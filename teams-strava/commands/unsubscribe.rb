module TeamsStrava
  module Commands
    class Unsubscribe < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      subscribe_command 'unsubscribe' do |request|
        if !request.team.stripe_customer_id
          logger.info "UNSUBSCRIBE: #{request}, unsubscribe failed, no subscription"
          "You don't have a paid subscription, all set."
        elsif request.user.team_owner?
          active_subscription = request.team.active_stripe_subscription
          if active_subscription && !active_subscription.cancel_at_period_end
            Stripe::Subscription.update(active_subscription.id, cancel_at_period_end: true)
            logger.info "UNSUBSCRIBE: #{request}, user=#{request.user}, canceled #{active_subscription.id}"
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            current_period_end = Time.at(active_subscription.current_period_end).strftime('%B %d, %Y')
            "Successfully canceled auto-renew to #{active_subscription.plan.nickname} (#{amount}), will expire on #{current_period_end}, and will not auto-renew."
          elsif active_subscription
            logger.info "UNSUBSCRIBE: #{request}, user=#{request.user}, already canceled #{active_subscription.id}"
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            current_period_end = Time.at(active_subscription.current_period_end).strftime('%B %d, %Y')
            "Subscription to #{active_subscription.plan.nickname} (#{amount}) is already set to expire on #{current_period_end}, and will not auto-renew."
          else
            logger.info "UNSUBSCRIBE: #{request}, user=#{request.user}"
            "You don't have a paid subscription. #{request.team.subscribe_text}"
          end
        else
          logger.info "UNSUBSCRIBE: #{request}, user=#{request.user} unsubscribe failed, not admin"
          'Sorry, only a team owner can do that.'
        end
      end
    end
  end
end
