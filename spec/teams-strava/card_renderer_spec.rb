require 'spec_helper'

describe TeamsStrava::CardRenderer do
  describe '.render_message' do
    it 'returns the plain string content when there are no embeds' do
      expect(described_class.render_message('hello')).to eq 'hello'
    end

    it 'returns the content when the message has no embeds' do
      message = { content: 'hello', embeds: [] }
      expect(described_class.render_message(message)).to eq 'hello'
    end

    it 'combines multiple embeds into a single card/attachment' do
      message = {
        content: 'activity',
        embeds: [
          { title: 'Run', fields: [{ name: 'Distance', value: '1mi' }], image: { url: 'https://example.com/map.png' } },
          { image: { url: 'https://example.com/photo.png' } }
        ]
      }

      activity = described_class.render_message(message)

      # A single attachment (Teams errors on update with "Activity resulted
      # into multiple skype activities" if more than one attachment/card is
      # sent in a single message).
      expect(activity.attachments.size).to eq 1

      card = activity.attachments.first['content']
      images = card.to_h['body'].select { |el| el['type'] == 'Image' }
      expect(images.map { |i| i['url'] }).to eq ['https://example.com/map.png', 'https://example.com/photo.png']
    end
  end
end
