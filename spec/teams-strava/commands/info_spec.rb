require 'spec_helper'

describe TeamsStrava::Commands::Info do
  include_context 'teams command' do
    let(:args) { ['info'] }
  end
  context 'subscribed team' do
    let(:team) { Fabricate(:team, subscribed: true) }

    it 'info' do
      expect(response).to eq TeamsStrava::INFO
    end
  end

  context 'non-subscribed team after trial' do
    let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }

    it 'does not mention a trial or pricing' do
      expect(response).to eq TeamsStrava::INFO
      expect(response).not_to match(/trial|free|subscribe|\$/i)
    end
  end

  context 'non-subscribed team during trial' do
    let(:team) { Fabricate(:team, created_at: 1.day.ago) }

    it 'does not mention a trial or pricing' do
      expect(response).to eq TeamsStrava::INFO
    end
  end
end
