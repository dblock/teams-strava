module TeamsStrava
  module Commands
    class Set < Command
      include TeamsStrava::Commands::Mixins::Subscribe
      include TeamsStrava::Loggable

      def self.parse_bool(value)
        return nil if value.nil? || value.blank?
        return true if value =~ /\A(true|on|yes)\z/i
        return false if value =~ /\A(false|off|no)\z/i

        raise TeamsStrava::Error, "Invalid value: #{value}. Please use true or false."
      end

      subscribe_command 'set' do |request|
        logger.info "SET: #{request}, #{request.user}"
        k, *rest = request.args.split(/\s+/)
        v = rest.join(' ')
        v = nil if v.blank?

        if k.blank?
          messages = [
            "Activities for team #{request.team.team_name} display *#{request.team.units_s}*.",
            "Activities for team #{request.team.team_name} display *#{request.team.temperature_s}*.",
            "Activities are retained for *#{request.team.retention_s}*.",
            "Timezone is *#{request.team.timezone_s}*.",
            "Max activities per user per day are *#{request.team.max_activities_per_user_per_day_s}*.",
            "Max activities per channel per day are *#{request.team.max_activities_per_channel_per_day_s}*.",
            "Activity fields are *#{request.team.activity_fields_s}*.",
            "Maps are *#{request.team.maps_s}*.",
            "Default leaderboard is *#{request.team.default_leaderboard_s}*.",
            "Your activities will #{'not ' unless request.user.sync_activities?}sync.",
            "Your private activities will #{'not ' unless request.user.private_activities?}be posted.",
            "Your followers only activities will #{'not ' unless request.user.followers_only_activities?}be posted."
          ]
          logger.info "SET: #{request.team}, user=#{request.user} - set"
          messages.join("\n")
        else
          case k.downcase
          when 'sync'
            bool = parse_bool(v)
            changed = !bool.nil? && request.user.sync_activities != bool
            request.user.update_attributes!(sync_activities: bool) unless bool.nil?
            logger.info "SET: #{request.team}, user=#{request.user} - sync set to #{request.user.sync_activities}"
            "Your activities will#{changed ? (request.user.sync_activities? ? ' now' : ' no longer') : (request.user.sync_activities? ? '' : ' not')} sync."
          when 'private'
            bool = parse_bool(v)
            changed = !bool.nil? && request.user.private_activities != bool
            request.user.update_attributes!(private_activities: bool) unless bool.nil?
            logger.info "SET: #{request.team}, user=#{request.user} - private set to #{request.user.private_activities}"
            "Your private activities will#{changed ? (request.user.private_activities? ? ' now' : ' no longer') : (request.user.private_activities? ? '' : ' not')} be posted."
          when 'followers'
            bool = parse_bool(v)
            changed = !bool.nil? && request.user.followers_only_activities != bool
            request.user.update_attributes!(followers_only_activities: bool) unless bool.nil?
            logger.info "SET: #{request.team}, user=#{request.user} - followers_only set to #{request.user.followers_only_activities}"
            "Your followers only activities will#{changed ? (request.user.followers_only_activities? ? ' now' : ' no longer') : (request.user.followers_only_activities? ? '' : ' not')} be posted."
          when 'units'
            case v
            when 'metric'
              v = 'km'
            when 'imperial'
              v = 'mi'
            end
            changed = v && request.team.units != v
            if !request.user.team_owner? && changed
              logger.info "SET: #{request.team} - not admin, units remain set to #{request.team.units}"
              "Sorry, only a team owner can change units. Activities for team #{request.team.team_name} display *#{request.team.units_s}*."
            else
              request.team.update_attributes!(units: v) unless v.nil?
              logger.info "SET: #{request.team} - units set to #{request.team.units}"
              "Activities for team #{request.team.team_name}#{' now' if changed} display *#{request.team.units_s}*."
            end
          when 'temperature'
            case v
            when 'celsius'
              v = 'c'
            when 'fahrenheit'
              v = 'f'
            end
            changed = v && request.team.temperature != v
            if !request.user.team_owner? && changed
              logger.info "SET: #{request.team} - not admin, temperature remains set to #{request.team.temperature}"
              "Sorry, only a team owner can change temperature. Activities for team #{request.team.team_name} display *#{request.team.temperature_s}*."
            else
              request.team.update_attributes!(temperature: v) unless v.nil?
              logger.info "SET: #{request.team} - temperature set to #{request.team.temperature}"
              "Activities for team #{request.team.team_name}#{' now' if changed} display *#{request.team.temperature_s}*."
            end
          when 'fields'
            parsed_fields = ActivityFields.parse_s(v) if v
            changed = parsed_fields && request.team.activity_fields != parsed_fields
            if !request.user.team_owner? && changed
              logger.info "SET: #{request.team} - not admin, activity fields remain set to #{request.team.activity_fields.and}"
              "Sorry, only a team owner can change fields. Activity fields for team #{request.team.team_name} are *#{request.team.activity_fields_s}*."
            else
              request.team.update_attributes!(activity_fields: parsed_fields) if changed && parsed_fields&.any?
              logger.info "SET: #{request.team} - activity fields set to #{request.team.activity_fields.and}"
              "Activity fields for team #{request.team.team_name} are#{' now' if changed} *#{request.team.activity_fields_s}*."
            end
          when 'maps'
            parsed_value = MapTypes.parse_s(v) if v
            changed = parsed_value && request.team.maps != parsed_value
            if !request.user.team_owner? && changed
              logger.info "SET: #{request.team} - not admin, maps remain set to #{request.team.maps}"
              "Sorry, only a team owner can change maps. Maps for team #{request.team.team_name} are *#{request.team.maps_s}*."
            else
              request.team.update_attributes!(maps: parsed_value) if parsed_value
              logger.info "SET: #{request.team} - maps set to #{request.team.maps}"
              "Maps for team #{request.team.team_name} are#{' now' if changed} *#{request.team.maps_s}*."
            end
          when 'leaderboard'
            v = nil if v&.blank?
            changed = v && request.team.default_leaderboard != v
            if !request.user.team_owner? && changed
              logger.info "SET: #{request.team} - not admin, default leaderboard remain set to #{request.team.default_leaderboard}"
              "Sorry, only a team owner can change the default leaderboard. Default leaderboard for team #{request.team.team_name} is *#{request.team.default_leaderboard_s}*."
            else
              request.team.update_attributes!(default_leaderboard: v) if Leaderboard.parse_expression(v) && changed
              logger.info "SET: #{request.team} - default leaderboard set to #{request.team.default_leaderboard}"
              "Default leaderboard for team #{request.team.team_name} is#{' now' if changed} *#{request.team.default_leaderboard_s}*."
            end
          when 'timezone'
            new_timezone = nil
            if v
              if v == 'auto'
                new_timezone = 'auto'
              else
                tz = ActiveSupport::TimeZone.new(v)
                raise TeamsStrava::Error, "TimeZone _#{v}_ is invalid, see https://github.com/rails/rails/blob/v#{ActiveSupport.gem_version}/activesupport/lib/active_support/values/time_zone.rb#L30 for a list. Timezone for team #{request.team.team_name} is currently *#{request.team.timezone_s}*." unless tz

                new_timezone = tz.name
              end
            end
            changed = new_timezone && request.team.timezone != new_timezone
            if !request.user.team_owner? && changed
              logger.info "SET: #{request.team} - not admin, timezone remains set to #{request.team.timezone}"
              "Sorry, only a team owner can change the timezone. Timezone for team #{request.team.team_name} is *#{request.team.timezone_s}*."
            else
              request.team.update_attributes!(timezone: new_timezone) if changed
              logger.info "SET: #{request.team} - timezone set to #{request.team.timezone}"
              "Timezone for team #{request.team.team_name} is#{' now' if changed} *#{request.team.timezone_s}*."
            end
          when 'retention'
            begin
              v = ChronicDuration.parse(v) if v
              changed = v && request.team.retention != v
              if !request.user.team_owner? && changed
                logger.info "SET: #{request.team} - not admin, default activity retention remains set to #{request.team.retention}"
                "Sorry, only a team owner can change activity retention. Activities in team #{request.team.team_name} are retained for *#{request.team.retention_s}*."
              else
                request.team.update_attributes!(retention: v) if changed
                logger.info "SET: #{request.team} - activity retention set to #{request.team.retention} (#{request.team.retention_s})"
                "Activities in team #{request.team.team_name} are#{' now' if changed} retained for *#{request.team.retention_s}*."
              end
            rescue ChronicDuration::DurationParseError => e
              e.to_s
            end
          when 'userlimit'
            if v
              raise TeamsStrava::Error, "Invalid value: #{v}. Please use a positive number or 'none'." unless v =~ /\A(none|\d+)\z/i

              v = v =~ /\Anone\z/i ? nil : v.to_i
            end
            changed = !rest.join.blank? && request.team.max_activities_per_user_per_day != v
            if !request.user.team_owner? && changed
              logger.info "SET: #{request.team} - not admin, max activities per user per day remains set to #{request.team.max_activities_per_user_per_day}"
              "Sorry, only a team owner can change the max activities per user per day. Max activities per user per day for team #{request.team.team_name} are *#{request.team.max_activities_per_user_per_day_s}*."
            else
              request.team.update_attributes!(max_activities_per_user_per_day: v) if changed
              logger.info "SET: #{request.team} - max activities per user per day set to #{request.team.max_activities_per_user_per_day}"
              "Max activities per user per day for team #{request.team.team_name} are#{' now' if changed} *#{request.team.max_activities_per_user_per_day_s}*."
            end
          when 'channellimit'
            if v
              raise TeamsStrava::Error, "Invalid value: #{v}. Please use a positive number or 'none'." unless v =~ /\A(none|\d+)\z/i

              v = v =~ /\Anone\z/i ? nil : v.to_i
            end
            changed = !rest.join.blank? && request.team.max_activities_per_channel_per_day != v
            if !request.user.team_owner? && changed
              logger.info "SET: #{request.team} - not admin, max activities per channel per day remains set to #{request.team.max_activities_per_channel_per_day}"
              "Sorry, only a team owner can change the max activities per channel per day. Max activities per channel per day for team #{request.team.team_name} are *#{request.team.max_activities_per_channel_per_day_s}*."
            else
              request.team.update_attributes!(max_activities_per_channel_per_day: v) if changed
              logger.info "SET: #{request.team} - max activities per channel per day set to #{request.team.max_activities_per_channel_per_day}"
              "Max activities per channel per day for team #{request.team.team_name} are#{' now' if changed} *#{request.team.max_activities_per_channel_per_day_s}*."
            end
          when 'activities'
            if v
              if v.casecmp('all').zero?
                v = []
              else
                parsed_types = v.split(/[\s,]+/).map do |t|
                  match = ActivityMethods::ACTIVITY_TYPES.find { |at| at.casecmp(t).zero? }
                  raise TeamsStrava::Error, "Invalid activity type: #{t}. Valid types are: #{ActivityMethods::ACTIVITY_TYPES.join(', ')}." unless match

                  match
                end
                v = parsed_types
              end
            end
            if request.user.team_owner?
              if v
                request.team.set_channel!(request.channel_id, request.channel_id, activity_types: v)
                logger.info "SET: #{request.team} - activity types for channel #{request.channel_id} set to #{request.team.channel_activity_types_s(request.channel_id)}"
              end
              "Activity types for this channel are#{' now' if v} *#{request.team.channel_activity_types_s(request.channel_id)}*."
            elsif v
              logger.info "SET: #{request.team} - not admin, activities for channel #{request.channel_id} unchanged"
              "Sorry, only a team owner can change the activity types for a channel. Activity types for this channel are *#{request.team.channel_activity_types_s(request.channel_id)}*."
            else
              "Activity types for this channel are *#{request.team.channel_activity_types_s(request.channel_id)}*."
            end
          else
            "Invalid setting #{k}, type `help` for instructions."
          end
        end
      end
    end
  end
end
