require 'spec_helper'

describe TeamsStrava::Commands::Stats do
  include_context 'teams command' do
    let(:args) { ['stats'] }
  end
  context 'stats' do
    # Beta: free for everyone, subscription enforcement disabled.
    it 'works without a subscription' do
      expect(response).to eq 'There are no activities in this channel.'
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
