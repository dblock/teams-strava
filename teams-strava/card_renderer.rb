module TeamsStrava
  # Converts the app's internal, platform-neutral "embed" hashes
  # (title/description/url/image/thumbnail/fields/author/timestamp) into
  # Teams Adaptive Cards. This lets model code (Activity, TeamStats, etc.)
  # stay unaware of the messaging platform.
  module CardRenderer
    module_function

    def render_card(embed)
      body = card_body(embed)
      return nil if body.empty?

      ::Teams::Cards::AdaptiveCard.new(*body)
    end

    # Renders a message, which is either a plain string or a hash with
    # :content and/or :embeds (the shape produced by Activity#to_message,
    # TeamStats#to_message, etc.) into something ctx.post/Bot#post accepts.
    #
    # All embeds are combined into a single Adaptive Card (one attachment).
    # Teams' update API errors with "Activity resulted into multiple skype
    # activities" (400 BadSyntax) when a single activity update carries more
    # than one attachment (e.g. an activity embed plus photo embeds), so we
    # can't render one card per embed the way Discord/Slack do.
    def render_message(message)
      return message unless message.is_a?(Hash)

      embeds = Array(message[:embeds]).compact
      return message[:content] if embeds.empty?

      activity = ::Teams::Api::MessageActivity.new(message[:content])
      body = embeds.flat_map { |embed| card_body(embed) }
      activity.add_card(::Teams::Cards::AdaptiveCard.new(*body)) unless body.empty?
      activity
    end

    def card_body(embed)
      return [] unless embed

      body = []
      body.concat(author_blocks(embed[:author])) if embed[:author]
      body << title_block(embed) if embed[:title]
      body << ::Teams::Cards::TextBlock.new(embed[:description], wrap: true) if embed[:description]

      facts = embed_facts(embed[:fields])
      body << ::Teams::Cards::FactSet.new(facts:) if facts.any?

      image_url = embed.dig(:image, :url) || embed.dig(:thumbnail, :url)
      body << ::Teams::Cards::Image.new(url: image_url, size: 'Stretch') if image_url

      body
    end

    def title_block(embed)
      text = embed[:url] ? "[#{embed[:title]}](#{embed[:url]})" : embed[:title].to_s
      ::Teams::Cards::TextBlock.new(text, size: 'Medium', weight: 'Bolder', wrap: true)
    end

    def author_blocks(author)
      text = author[:url] ? "[#{author[:name]}](#{author[:url]})" : author[:name].to_s
      [::Teams::Cards::TextBlock.new(text, weight: 'Bolder', wrap: true)]
    end

    def embed_facts(fields)
      Array(fields).map do |field|
        ::Teams::Cards::Fact.new(title: field[:name].to_s, value: field[:value].to_s)
      end
    end
  end
end
