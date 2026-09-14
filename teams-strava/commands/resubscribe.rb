module TeamsStrava
  module Commands
    class Resubscribe < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      subscribe_command 'resubscribe' do |request|
        if !request.team.stripe_customer_id
          logger.info "RESUBSCRIBE: #{request}, resubscribe failed, no subscription"
          "You don't have a paid subscription. #{request.team.subscribe_text}"
        elsif request.user.team_owner?
          active_subscription = request.team.active_stripe_subscription
          if active_subscription&.cancel_at_period_end
            Stripe::Subscription.update(active_subscription.id, cancel_at_period_end: false)
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            logger.info "RESUBSCRIBE: #{request}, user=#{request.user}, auto-renew #{active_subscription.id}"
            current_period_end = Time.at(active_subscription.current_period_end).strftime('%B %d, %Y')
            "Subscription to #{active_subscription.plan.nickname} (#{amount}) will now auto-renew on #{current_period_end}."
          elsif active_subscription
            logger.info "RESUBSCRIBE: #{request}, user=#{request.user}, already renewing"
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            current_period_end = Time.at(active_subscription.current_period_end).strftime('%B %d, %Y')
            "Subscription to #{active_subscription.plan.nickname} (#{amount}) will continue to auto-renew on #{current_period_end}."
          else
            logger.info "RESUBSCRIBE: #{request}, user=#{request.user}"
            "You don't have a paid subscription. #{request.team.subscribe_text}"
          end
        else
          logger.info "RESUBSCRIBE: #{request}, user=#{request.user} resubscribe failed, not admin"
          'Sorry, only a team owner can do that.'
        end
      end
    end
  end
end
