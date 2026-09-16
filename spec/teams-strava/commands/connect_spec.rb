require 'spec_helper'

describe TeamsStrava::Commands::Connect do
  include_context 'teams command' do
    let(:args) { ['connect'] }
  end
  context 'connect' do
    let(:url) { "https://www.strava.com/oauth/authorize?client_id=client-id&redirect_uri=https://strata.playplay.io/connect&response_type=code&scope=activity:read_all&state=#{user.id}" }

    # Beta: free for everyone, trial/subscription enforcement disabled.
    it 'connects a user regardless of subscription status' do
      expect(response).to be_a(Teams::Api::MessageActivity)
      content = response.to_h.dig('attachments', 0, 'content')
      expect(content['type']).to eq 'AdaptiveCard'
      expect(content['body'].first).to include('type' => 'TextBlock', 'text' => 'Please connect your Strava account.')
      expect(content['actions'].first).to include('type' => 'Action.OpenUrl', 'title' => 'Connect!', 'url' => url)
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      it 'connects a user' do
        expect(response).to be_a(Teams::Api::MessageActivity)
        content = response.to_h.dig('attachments', 0, 'content')
        expect(content['type']).to eq 'AdaptiveCard'
        expect(content['body'].first).to include('type' => 'TextBlock', 'text' => 'Please connect your Strava account.')
        expect(content['actions'].first).to include('type' => 'Action.OpenUrl', 'title' => 'Connect!', 'url' => url)
      end
    end

    context 'team past the normal trial period' do
      before do
        team.update_attributes!(created_at: 3.weeks.ago)
      end

      # Beta: free for everyone, subscription expiration enforcement disabled.
      it 'still connects a user' do
        expect(response).to be_a(Teams::Api::MessageActivity)
        content = response.to_h.dig('attachments', 0, 'content')
        expect(content['actions'].first).to include('type' => 'Action.OpenUrl', 'title' => 'Connect!', 'url' => url)
      end
    end
  end
end
