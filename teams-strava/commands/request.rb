module TeamsStrava
  module Commands
    # Wraps an inbound Teams activity context, parsing its (mention-stripped)
    # text into a command name and the remaining argument string, and
    # resolves the Team/User records for the conversation.
    class Request
      include TeamsStrava::Loggable

      attr_reader :ctx

      def initialize(ctx)
        @ctx = ctx
      end

      def activity
        ctx.activity
      end

      def personal?
        activity.conversation.conversation_type == 'personal'
      end

      # Only respond in a 1:1 chat, or when the bot is @mentioned in a
      # channel/group chat, to avoid replying to every message.
      def command?
        return false unless activity.message?
        return false if activity.from.id == activity.recipient.id

        personal? || activity.recipient_mentioned?
      end

      def text
        @text ||= (personal? ? activity.text : activity.strip_mentions_text).to_s.strip
      end

      def name
        @name ||= text.split(/\s+/).first.to_s.downcase
      end

      def args
        @args ||= text.split(/\s+/)[1..].to_a.join(' ')
      end

      def matches?(route)
        route == '*' || route == name
      end

      def team
        @team ||= Team.find_by_activity!(activity)
      end

      def user
        @user ||= team.users.where(
          user_id:,
          channel_id:
        ).first || User.create!(
          team:,
          user_id:,
          channel_id:,
          service_url:,
          user_name: username
        )
      end

      def channel_id
        activity.conversation.id
      end

      def service_url
        activity.service_url
      end

      def user_id
        activity.from.aad_object_id || activity.from.id
      end

      def username
        activity.from.name
      end

      def to_s
        [
          "command=#{[name, args].reject(&:blank?).join(' ')}",
          "team=#{team}"
        ].compact.join(', ')
      end
    end
  end
end
