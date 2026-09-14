module TeamsStrava
  # Thin wrapper around a shared Teams::App instance (teams_rb). A single
  # app-level bot token (client credentials) is used for every team/tenant;
  # there is no per-team OAuth token to manage.
  class Bot
    include TeamsStrava::Loggable

    class << self
      def instance
        @instance ||= new
      end

      def reset!
        @instance = nil
      end
    end

    def app
      @app ||= build_app
    end

    def api
      app.api
    end

    def to_rack
      app.to_rack
    end

    # Sends/updates a message in a conversation (channel, group chat or 1:1).
    def send_message(conversation_id, service_url, message)
      app.post(conversation_id, TeamsStrava::CardRenderer.render_message(message), service_url:)
    rescue StandardError => e
      handle_error(e)
    end

    def update_message(conversation_id, service_url, activity_id, message)
      app.update(conversation_id, activity_id, TeamsStrava::CardRenderer.render_message(message), service_url:)
    rescue StandardError => e
      handle_error(e)
    end

    def delete_message(conversation_id, service_url, activity_id)
      api.conversations.delete_activity(conversation_id, activity_id, service_url:)
      nil
    rescue StandardError => e
      handle_error(e)
    end

    # Creates (or re-fetches) a 1:1 conversation with a Teams member and
    # sends a message.
    def send_dm(teams_user_id, tenant_id, message)
      conversation = api.conversations.create(members: [{ id: teams_user_id }], tenant_id:)
      send_message(conversation.id, conversation.service_url, message)
    rescue StandardError => e
      handle_error(e)
    end

    # Verifies a team is still reachable.
    def info(team_id)
      api.teams.get_by_id(team_id)
    rescue StandardError => e
      handle_error(e)
    end

    def member(conversation_id, member_id)
      api.conversations.get_member_by_id(conversation_id, member_id)
    rescue StandardError => e
      handle_error(e)
    end

    private

    def build_app
      teams_app = ::Teams::App.new(
        client_id: ENV.fetch('CLIENT_ID', nil),
        client_secret: ENV.fetch('CLIENT_SECRET', nil),
        tenant_id: ENV.fetch('TENANT_ID', nil),
        dangerously_allow_unauthenticated_requests: ENV['RACK_ENV'] != 'production'
      )
      register_handlers!(teams_app)
      teams_app
    end

    def register_handlers!(teams_app)
      teams_app.on_message do |ctx|
        handle_message!(ctx)
      end

      teams_app.on_conversation_update do |ctx|
        handle_conversation_update!(ctx)
      end
    end

    def handle_message!(ctx)
      request = TeamsStrava::Commands::Request.new(ctx)
      return unless request.command?

      result = TeamsStrava::Commands.invoke!(request)
      ctx.reply(result) if result
    rescue TeamsStrava::Error => e
      ctx.reply(e.message)
    rescue StandardError => e
      logger.error e
      NewRelic::Agent.notice_error(e)
      ctx.reply('Sorry, something went wrong.')
    end

    def handle_conversation_update!(ctx)
      Team.install_or_update!(ctx)
    rescue StandardError => e
      logger.error e
      NewRelic::Agent.notice_error(e)
    end

    def handle_error(err)
      raise TeamsStrava::Error, "#{err.message} (#{err.status})" if err.is_a?(::Teams::HttpError)

      raise TeamsStrava::Error, "#{err.class}: #{err.message}"
    end
  end
end
