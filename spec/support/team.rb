RSpec.shared_context 'team activation', shared_context: :metadata do
  before do
    allow(TeamsStrava::Bot.instance).to receive_messages(
      info: OpenStruct.new(
        id: 'team_id',
        name: 'team name'
      ),
      send_message: OpenStruct.new(
        id: 'message_id'
      ),
      update_message: OpenStruct.new(
        id: 'message_id'
      ),
      send_dm: OpenStruct.new(
        id: 'message_id'
      ),
      member: OpenStruct.new(
        id: 'user_id',
        name: 'user name'
      )
    )
  end
end
