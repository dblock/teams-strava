module TeamsStrava
  module Commands
    class Subscription < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      subscribe_command 'subscription' do |request|
        logger.info "SUBSCRIPTION: #{request}"
        request.team.subscription_info
      end
    end
  end
end
