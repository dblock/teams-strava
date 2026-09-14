require 'spec_helper'

describe TeamsStrava::Bot do
  subject do
    described_class.instance
  end

  def activity_for(conversation_type:, team: nil, members_added: nil)
    Teams::Activity.new(
      type: 'conversationUpdate',
      recipient: { id: 'bot-id', name: 'Strata' },
      from: { id: 'installer-id', name: 'Installer Name', aadObjectId: 'installer-id' },
      conversation: { id: 'conversation-id', conversationType: conversation_type },
      serviceUrl: 'https://smba.trafficmanager.net/amer/',
      channelData: team ? { team: { id: team, name: 'Team Name' }, tenant: { id: 'tenant-id' } } : {},
      membersAdded: members_added
    )
  end

  describe '#handle_conversation_update!' do
    context 'when installed at team scope' do
      let(:activity) { activity_for(conversation_type: 'channel', team: 'team-id', members_added: [{ id: 'bot-id' }]) }
      let(:ctx) { double('ctx', activity:) }

      before do
        allow_any_instance_of(Team).to receive(:inform_activated!)
        allow_any_instance_of(Team).to receive(:update_info!)
        allow(TeamsStrava::Service.instance).to receive(:create!)
      end

      it 'creates a team and does not reply' do
        expect(ctx).not_to receive(:reply)
        subject.send(:handle_conversation_update!, ctx)
        expect(Team.where(team_id: 'team-id').first).not_to be_nil
      end
    end

    context 'when installed at personal scope' do
      let(:activity) { activity_for(conversation_type: 'personal', members_added: [{ id: 'bot-id' }]) }
      let(:ctx) { double('ctx', activity:) }

      it 'does not create a team and replies with an error' do
        expect(ctx).to receive(:reply).with('Strata works best in a regular Teams channel. Add me to a team to get started.')
        subject.send(:handle_conversation_update!, ctx)
        expect(Team.count).to eq 0
      end
    end

    context 'when another member is added to an existing personal conversation' do
      let(:activity) { activity_for(conversation_type: 'personal', members_added: [{ id: 'someone-else' }]) }
      let(:ctx) { double('ctx', activity:) }

      it 'does not reply' do
        expect(ctx).not_to receive(:reply)
        subject.send(:handle_conversation_update!, ctx)
      end
    end
  end
end
