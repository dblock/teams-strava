require 'spec_helper'

describe TeamsStrava::Commands::Connect do
  include_context 'teams command' do
    let(:args) { ['connect'] }
  end
  context 'connect' do
    it 'requires a subscription' do
      expect(response).to eq team.trial_message
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }
      let(:url) { "https://www.strava.com/oauth/authorize?client_id=client-id&redirect_uri=https://strata.playplay.io/connect&response_type=code&scope=activity:read_all&state=#{user.id}" }

      it 'connects a user' do
        expect(response).to be_a(Teams::Api::MessageActivity)
        content = response.to_h.dig('attachments', 0, 'content')
        expect(content['type']).to eq 'AdaptiveCard'
        expect(content['body'].first).to include('type' => 'TextBlock', 'text' => 'Please connect your Strava account.')
        expect(content['actions'].first).to include('type' => 'Action.OpenUrl', 'title' => 'Connect!', 'url' => url)
      end
    end

    context 'subscription expiration' do
      before do
        team.update_attributes!(created_at: 3.weeks.ago)
      end

      it 'prevents new connections' do
        expect(response).to eq "Your trial subscription has expired. Subscribe your team for $19.99 a year at https://strata.playplay.io/subscribe?team_id=#{team.id} to continue receiving Strava activities in Teams. Proceeds go to NYRR."
      end
    end
  end
end
