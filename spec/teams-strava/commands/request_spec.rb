require 'spec_helper'

describe TeamsStrava::Commands::Request do
  include_context 'teams command'

  let(:args) { %w[help] }

  describe '#channel_id' do
    context 'with a plain conversation id' do
      it 'returns the conversation id unchanged' do
        expect(command.channel_id).to eq user.channel_id
      end
    end

    context 'with a conversation id that includes a messageid suffix' do
      let(:activity_hash) do
        super().deep_merge(
          conversation: { id: "#{user.channel_id};messageid=1234567890" }
        )
      end

      it 'strips the messageid suffix so future posts are not threaded' do
        expect(command.channel_id).to eq user.channel_id
      end
    end
  end
end
