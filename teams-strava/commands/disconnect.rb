module TeamsStrava
  module Commands
    class Disconnect < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      subscribe_command 'disconnect' do |request|
        target_name = request.args.to_s.strip
        if target_name.present?
          if request.user.team_owner?
            target_user = request.team.users.where(user_name: /\A#{Regexp.escape(target_name)}\z/i).first
            if target_user&.connected_to_strava?
              logger.info "DISCONNECT: #{request}, user=#{request.user}, #{target_user}"
              target_user.disconnect!
              "Strava account for user #{target_user.teams_mention} successfully disconnected."
            elsif target_user
              logger.info "DISCONNECT: #{request}, user=#{request.user}, #{target_user} - already disconnected"
              "Strava account for user #{target_user.teams_mention} is already disconnected."
            else
              logger.info "DISCONNECT: #{request}, user=#{request.user}, target=#{target_name} - not found"
              "I cannot find the user #{target_name}, sorry."
            end
          else
            logger.info "DISCONNECT: #{request}, user=#{request.user}, target=#{target_name} - not admin"
            'Sorry, only a team owner can disconnect other users.'
          end
        else
          logger.info "DISCONNECT: #{request}"
          request.user.disconnect!
        end
      end
    end
  end
end
