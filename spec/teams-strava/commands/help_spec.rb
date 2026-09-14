require 'spec_helper'

describe TeamsStrava::Commands::Help do
  include_context 'teams command' do
    let(:args) { ['help'] }
  end
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }

    it 'help' do
      expect(response).to eq TeamsStrava::Commands::Help::HELP
    end
  end

  context 'non-subscribed team after trial' do
    let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }

    it 'help' do
      expect(response).to eq([
        TeamsStrava::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
    end
  end

  context 'non-subscribed team during trial' do
    let!(:team) { Fabricate(:team, created_at: 1.day.ago) }

    it 'help' do
      expect(response).to eq([
        TeamsStrava::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
    end
  end
end
