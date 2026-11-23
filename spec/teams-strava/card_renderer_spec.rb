require 'spec_helper'

describe TeamsStrava::CardRenderer do
  describe '.card_body' do
    let(:embed) do
      {
        author: { name: 'D B', url: 'https://www.strava.com/athletes/123' },
        title: 'Morning Run',
        url: 'https://www.strava.com/activities/456'
      }
    end
    let(:blocks) { described_class.card_body(embed).map(&:to_h) }

    it 'does not link the author or title' do
      expect(blocks[0]['text']).to eq 'D B'
      expect(blocks[1]['text']).to eq 'Morning Run'
    end

    it 'links back to Strava with "View on Strava"' do
      expect(blocks.last).to include('type' => 'TextBlock', 'text' => '**[View on Strava](https://www.strava.com/activities/456)**')
    end

    it 'does not add a Strava link without a url' do
      texts = described_class.card_body({ title: 'Stats' }).map { |block| block.to_h['text'] }
      expect(texts).to eq ['Stats']
    end
  end

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
