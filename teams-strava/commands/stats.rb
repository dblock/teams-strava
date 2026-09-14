module TeamsStrava
  module Commands
    class Stats < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      class << self
        include TeamsStrava::Commands::Mixins::ParseDate
      end

      subscribe_command 'stats' do |request|
        logger.info "STATS: #{request}"
        stats_options = begin
          Stats.parse_date_expression(request.args, now: request.team.now)
        rescue TeamsStrava::Error
          {}
        end
        stats_options[:channel_id] = request.channel_id
        logger.info "STATS: #{request.team}, dates=#{stats_options[:start_date]}..#{stats_options[:end_date]}, channel=#{request.channel_id}"
        request.team.stats(stats_options).to_message
      end
    end
  end
end
