module TeamsStrava
  module Commands
    class Connect < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      subscribe_command 'connect' do |request|
        logger.info "CONNECT: #{request}, #{request.user}"
        request.user.connect_to_strava
      end
    end
  end
end
