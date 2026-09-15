module TeamsStrava
  module Commands
    class Connect < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      subscribe_command 'connect' do |request|
        logger.info "CONNECT: #{request}, #{request.user}"
        if request.user.connected_to_strava?
          "Your Strava account is already connected, #{request.user.teams_mention}."
        else
          request.user.dm_connect!
          "I've sent you a private message to connect your Strava account, #{request.user.teams_mention}."
        end
      end
    end
  end
end
