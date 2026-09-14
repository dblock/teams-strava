require 'spec_helper'

describe TeamsStrava::Commands::Info do
  include_context 'teams command' do
    let(:args) { ['info'] }
  end
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }

    it 'info' do
      expect(response).to eq TeamsStrava::INFO
    end
  end

  context 'non-subscribed team after trial' do
    let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }

    it 'info' do
      expect(response).to eq([
        TeamsStrava::INFO,
        team.trial_message
      ].join("\n"))
    end
  end

  context 'non-subscribed team during trial' do
    let!(:team) { Fabricate(:team, created_at: 1.day.ago) }

    it 'info' do
      expect(response).to eq([
        TeamsStrava::INFO,
        team.trial_message
      ].join("\n"))
    end
  end
end
