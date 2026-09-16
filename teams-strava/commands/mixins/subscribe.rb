module TeamsStrava
  module Commands
    module Mixins
      module Subscribe
        extend ActiveSupport::Concern

        module ClassMethods
          def subscribe_command(*values, &)
            command(*values) do |command| # rubocop:disable Style/ExplicitBlockArgument -- kept as a block for readability of the disabled trial logic below
              # Beta: free for everyone, trial/subscription enforcement disabled.
              # if Stripe.api_key && command.team.reload.subscription_expired?
              #   logger.info "#{command}, subscribed feature required"
              #   command.team.trial_message
              # else
              yield command
              # end
            end
          end
        end
      end
    end
  end
end
