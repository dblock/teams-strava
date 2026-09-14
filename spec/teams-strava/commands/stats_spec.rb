require 'spec_helper'

describe TeamsStrava::Commands::Stats do
  include_context 'teams command' do
    let(:args) { ['stats'] }
  end
  context 'stats' do
    it 'requires a subscription' do
      expect(response).to eq team.trial_message
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'channel' do
        it 'displays channel stats' do
          expect(response).to eq(team.stats(channel_id: user.channel_id).to_message)
        end
      end
    end
  end
end
