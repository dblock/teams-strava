module TeamsStrava
  module Commands
    class Leaderboard < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      class << self
        include TeamsStrava::Commands::Mixins::ParseDate

        def parse_expression(expression, now: Time.now)
          result = { metric: 'distance' }
          return result if expression.nil?

          expression = expression.strip

          TeamLeaderboard::MEASURABLE_VALUES.each do |metric|
            next unless expression.match?(/^(#{Regexp.escape(metric.split('_').join(' '))}|#{Regexp.escape(metric)})(?:\s|$)/i)

            result[:metric] = metric
            expression = expression[metric.length..]&.strip
            break
          end

          expression = expression.strip

          result.merge(parse_date_expression(expression, now: now))
        end
      end

      subscribe_command 'leaderboard' do |request|
        combined_options = request.args.presence || request.team.default_leaderboard
        range_options = Leaderboard.parse_expression(combined_options, now: request.team.now)
        logger.info "LEADERBOARD: #{request}, metric=#{range_options[:metric]}, range=#{range_options[:start_date]}..#{range_options[:end_date]}"
        request.team.leaderboard(
          range_options.merge(
            channel_id: request.channel_id
          )
        ).to_message
      end
    end
  end
end
