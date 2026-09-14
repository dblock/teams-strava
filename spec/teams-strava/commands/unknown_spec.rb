require 'spec_helper'

describe TeamsStrava::Commands::Unknown do
  include_context 'teams command'

  context 'unrecognized command' do
    let(:args) { ['invalid'] }

    it 'fails with an error' do
      expect(response).to eq "Sorry, I don't understand that command. Type `help` to get help."
    end
  end

  context 'no args' do
    it 'fails with an error' do
      expect(response).to eq "Sorry, I don't understand that command. Type `help` to get help."
    end
  end

  context 'multiple args' do
    let(:args) { %w[foo bar baz] }

    it 'fails with an error' do
      expect(response).to eq "Sorry, I don't understand that command. Type `help` to get help."
    end
  end
end
