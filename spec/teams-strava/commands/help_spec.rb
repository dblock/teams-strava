require 'spec_helper'

describe TeamsStrava::Commands::Help do
  include_context 'teams command' do
    let(:args) { ['help'] }
  end
  context 'subscribed team' do
    let(:team) { Fabricate(:team, subscribed: true) }

    it 'help' do
      expect(response).to eq TeamsStrava::Commands::Help::HELP
    end
  end

  context 'non-subscribed team after trial' do
    let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }

    it 'does not mention a trial or pricing' do
      expect(response).to eq TeamsStrava::Commands::Help::HELP
      expect(response).not_to match(/trial|free|subscribe|\$/i)
    end
  end

  context 'non-subscribed team during trial' do
    let(:team) { Fabricate(:team, created_at: 1.day.ago) }

    it 'does not mention a trial or pricing' do
      expect(response).to eq TeamsStrava::Commands::Help::HELP
    end
  end
end
