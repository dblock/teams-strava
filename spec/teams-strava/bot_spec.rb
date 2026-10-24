require 'spec_helper'

describe TeamsStrava::Bot do
  subject do
    described_class.instance
  end

  def activity_for(conversation_type:, team: nil, members_added: nil)
    Teams::Activity.new(
      type: 'conversationUpdate',
      recipient: { id: 'bot-id', name: 'Strata' },
      from: { id: 'installer-id', name: 'Installer Name', aadObjectId: 'installer-id' },
      conversation: { id: 'conversation-id', conversationType: conversation_type },
      serviceUrl: 'https://smba.trafficmanager.net/amer/',
      channelData: team ? { team: { id: team, name: 'Team Name' }, tenant: { id: 'tenant-id' } } : {},
      membersAdded: members_added
    )
  end

  describe '#to_rack' do
    let(:service_url) { 'https://smba.trafficmanager.net/amer/' }
    let(:keys) { Array.new(2) { OpenSSL::PKey::RSA.generate(2048) } }
    let(:jwks) { { keys: [public_jwk(keys.first, 'original')] } }
    let(:activity) do
      {
        type: 'message',
        text: 'help',
        from: { id: 'user-id', name: 'Test User' },
        recipient: { id: 'bot-id', name: 'Strata' },
        conversation: { id: 'conversation-id', conversationType: 'personal' },
        serviceUrl: service_url
      }
    end

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('RACK_ENV').and_return('production')
      stub_request(:get, 'https://login.botframework.com/v1/.well-known/openidconfiguration')
        .to_return(body: { jwks_uri: 'https://login.botframework.com/v1/.well-known/keys' }.to_json)
      stub_request(:get, 'https://login.botframework.com/v1/.well-known/keys')
        .to_return { { body: jwks.to_json, headers: { 'Content-Type' => 'application/json' } } }
    end

    def public_jwk(key, kid)
      {
        kid:,
        kty: 'RSA',
        n: Base64.urlsafe_encode64(key.n.to_s(2), padding: false),
        e: Base64.urlsafe_encode64(key.e.to_s(2), padding: false)
      }
    end

    def authenticated_request(key, kid)
      header = Base64.urlsafe_encode64({ alg: 'RS256', kid: }.to_json, padding: false)
      payload = Base64.urlsafe_encode64({
        iss: 'https://api.botframework.com',
        aud: ENV.fetch('CLIENT_ID'),
        nbf: Time.now.to_i - 60,
        exp: Time.now.to_i + 3600,
        serviceurl: service_url
      }.to_json, padding: false)
      input = "#{header}.#{payload}"
      signature = Base64.urlsafe_encode64(key.sign(OpenSSL::Digest.new('SHA256'), input), padding: false)
      subject.to_rack.call(
        'REQUEST_METHOD' => 'POST',
        'PATH_INFO' => '/api/messages',
        'rack.input' => StringIO.new(activity.to_json),
        'HTTP_AUTHORIZATION' => "Bearer #{input}.#{signature}"
      )
    end

    it 'continues dispatching authenticated commands immediately after Microsoft rotates signing keys' do
      expect(TeamsStrava::Commands).to receive(:invoke!).twice do |request|
        expect(request.name).to eq 'help'
        nil
      end

      expect(authenticated_request(keys.first, 'original').first).to eq 200
      jwks[:keys] << public_jwk(keys.last, 'rotated')
      expect(authenticated_request(keys.last, 'rotated').first).to eq 200
      expect(WebMock).to have_requested(:get, 'https://login.botframework.com/v1/.well-known/keys').twice
    end

    it 'rejects an unknown signing key without dispatching a command' do
      expect(TeamsStrava::Commands).not_to receive(:invoke!)
      expect(authenticated_request(keys.last, 'unknown').first).to eq 401
    end
  end

  describe '#handle_conversation_update!' do
    context 'when installed at team scope' do
      let(:activity) { activity_for(conversation_type: 'channel', team: 'team-id', members_added: [{ id: 'bot-id' }]) }
      let(:ctx) { double('ctx', activity:) }

      before do
        allow_any_instance_of(Team).to receive(:inform_activated!)
        allow_any_instance_of(Team).to receive(:update_info!)
        allow(TeamsStrava::Service.instance).to receive(:create!)
      end

      it 'creates a team and does not post' do
        expect(ctx).not_to receive(:post)
        subject.send(:handle_conversation_update!, ctx)
        expect(Team.where(team_id: 'team-id').first).not_to be_nil
      end
    end

    context 'when installed at personal scope' do
      let(:activity) { activity_for(conversation_type: 'personal', members_added: [{ id: 'bot-id' }]) }
      let(:ctx) { double('ctx', activity:) }

      it 'does not create a team and posts an error' do
        expect(ctx).to receive(:post).with('Strata works best in a regular Teams channel. Add me to a team to get started.')
        subject.send(:handle_conversation_update!, ctx)
        expect(Team.count).to eq 0
      end
    end

    context 'when another member is added to an existing personal conversation' do
      let(:activity) { activity_for(conversation_type: 'personal', members_added: [{ id: 'someone-else' }]) }
      let(:ctx) { double('ctx', activity:) }

      it 'does not post' do
        expect(ctx).not_to receive(:post)
        subject.send(:handle_conversation_update!, ctx)
      end
    end
  end
end
