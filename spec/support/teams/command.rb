require 'spec_helper'

RSpec.shared_context 'teams command', shared_context: :metadata do
  include_context 'team activation'

  let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
  let(:user) { Fabricate(:user, team:) }
  let(:args) { [] }
  let(:text) { Array(args).join(' ') }
  let(:mention_text) { '<at>Strata</at>' }
  let(:personal) { false }
  let(:activity_hash) do
    {
      type: 'message',
      text: personal ? text : "#{mention_text} #{text}".strip,
      from: {
        id: user.user_id,
        name: user.user_name,
        aadObjectId: user.user_id
      },
      recipient: {
        id: 'bot-id',
        name: 'Strata'
      },
      conversation: {
        id: user.channel_id,
        conversationType: personal ? 'personal' : 'channel'
      },
      serviceUrl: user.service_url,
      channelData: {
        team: {
          id: team.team_id,
          name: team.team_name
        },
        tenant: {
          id: team.tenant_id
        }
      },
      entities: if personal
                  []
                else
                  [
                    {
                      type: 'mention',
                      text: mention_text,
                      mentioned: {
                        id: 'bot-id',
                        name: 'Strata'
                      }
                    }
                  ]
                end
    }
  end
  let(:activity) { Teams::Activity.new(activity_hash) }
  let(:ctx) { double('ctx', activity:) }
  let(:command) { TeamsStrava::Commands::Request.new(ctx) }
  let(:response) { TeamsStrava::Commands.invoke!(command) }
end
