require 'spec_helper'

describe Team do
  include_context 'team activation'

  describe '.install_or_update!' do
    let(:activity_hash) do
      {
        type: 'conversationUpdate',
        from: {
          id: 'fallback-installer-id',
          name: 'Installer Name',
          aadObjectId: 'installer-id'
        },
        conversation: {
          id: 'conversation-id',
          conversationType: 'channel'
        },
        serviceUrl: 'https://smba.trafficmanager.net/amer/',
        channelData: {
          team: {
            id: 'team-id',
            name: 'Team Name'
          },
          tenant: {
            id: 'tenant-id'
          }
        }
      }
    end
    let(:activity) { Teams::Activity.new(activity_hash) }
    let(:ctx) { Struct.new(:activity).new(activity) }

    before do
      allow_any_instance_of(described_class).to receive(:inform_activated!)
      allow_any_instance_of(described_class).to receive(:update_info!)
    end

    it 'creates a team from the installation activity' do
      expect(TeamsStrava::Service.instance).to receive(:create!)

      expect {
        described_class.install_or_update!(ctx)
      }.to change(described_class, :count).by(1)

      team = described_class.last
      expect(team.team_id).to eq 'team-id'
      expect(team.team_name).to eq 'Team Name'
      expect(team.tenant_id).to eq 'tenant-id'
      expect(team.conversation_id).to eq 'conversation-id'
      expect(team.service_url).to eq 'https://smba.trafficmanager.net/amer/'
      expect(team.installer_id).to eq 'installer-id'
      expect(team.installer_name).to eq 'Installer Name'
      expect(team.active).to be true
    end

    context 'with an existing team' do
      let!(:team) do
        Fabricate(
          :team,
          team_id: 'team-id',
          team_name: 'Old Team Name',
          tenant_id: 'old-tenant-id',
          conversation_id: 'old-conversation-id',
          service_url: 'https://old.example',
          installer_id: 'old-installer-id',
          installer_name: 'Old Installer',
          active: false
        )
      end

      it 'updates the existing record without restarting setup' do
        expect(TeamsStrava::Service.instance).not_to receive(:create!)

        expect {
          described_class.install_or_update!(ctx)
        }.not_to change(described_class, :count)

        expect(team.reload.attributes.slice('team_name', 'tenant_id', 'conversation_id', 'service_url', 'installer_id', 'installer_name', 'active')).to eq(
          'team_name' => 'Team Name',
          'tenant_id' => 'tenant-id',
          'conversation_id' => 'conversation-id',
          'service_url' => 'https://smba.trafficmanager.net/amer/',
          'installer_id' => 'installer-id',
          'installer_name' => 'Installer Name',
          'active' => true
        )
      end
    end

    context 'without a team in channel data' do
      let(:activity_hash) do
        {
          type: 'conversationUpdate',
          from: { id: 'user-id', name: 'Installer Name', aadObjectId: 'installer-id' },
          conversation: { id: 'conversation-id', conversationType: 'personal' },
          serviceUrl: 'https://smba.trafficmanager.net/amer/',
          channelData: {
            tenant: {
              id: 'tenant-id'
            }
          }
        }
      end

      it 'does nothing' do
        expect(TeamsStrava::Service.instance).not_to receive(:create!)
        expect(described_class.install_or_update!(ctx)).to be_nil
      end
    end
  end

  describe '.find_by_activity!' do
    let!(:team) { Fabricate(:team, team_id: 'team-id') }

    it 'finds a team from the activity payload' do
      activity = Teams::Activity.new(
        type: 'message',
        conversation: { id: 'conversation-id', conversationType: 'channel' },
        channelData: { team: { id: 'team-id' } }
      )

      expect(described_class.find_by_activity!(activity)).to eq team
    end

    it 'raises when used outside a regular team channel' do
      activity = Teams::Activity.new(type: 'message', conversation: { id: 'conversation-id', conversationType: 'personal' }, channelData: {})

      expect {
        described_class.find_by_activity!(activity)
      }.to raise_error(TeamsStrava::Error, 'Strata works best in a regular Teams channel.')
    end

    it 'raises when the team has not been installed yet' do
      activity = Teams::Activity.new(
        type: 'message',
        conversation: { id: 'conversation-id', conversationType: 'channel' },
        channelData: { team: { id: 'missing-team-id' } }
      )

      expect {
        described_class.find_by_activity!(activity)
      }.to raise_error(TeamsStrava::Error, 'Missing team with team_id=missing-team-id.')
    end
  end

  describe '#purge!' do
    let!(:active_team) { Fabricate(:team) }
    let!(:inactive_team) { Fabricate(:team, active: false) }
    let!(:inactive_team_one_week_ago) { Fabricate(:team, updated_at: 1.week.ago, active: false) }
    let!(:inactive_team_two_weeks_ago) { Fabricate(:team, updated_at: 2.weeks.ago, active: false) }
    let!(:inactive_team_a_month_ago) { Fabricate(:team, updated_at: 1.month.ago, active: false) }

    it 'destroys teams inactive for two weeks' do
      expect {
        described_class.purge!
      }.to change(described_class, :count).by(-2)
      expect(described_class.find(active_team.id)).to eq active_team
      expect(described_class.find(inactive_team.id)).to eq inactive_team
      expect(described_class.find(inactive_team_one_week_ago.id)).to eq inactive_team_one_week_ago
      expect(described_class.find(inactive_team_two_weeks_ago.id)).to be_nil
      expect(described_class.find(inactive_team_a_month_ago.id)).to be_nil
    end

    context 'with a subscribed team' do
      before do
        inactive_team_a_month_ago.set(subscribed: true)
      end

      it 'does not destroy team the subscribed team' do
        expect {
          described_class.purge!
        }.to change(described_class, :count).by(-1)
        expect(described_class.find(inactive_team_two_weeks_ago.id)).to be_nil
        expect(described_class.find(inactive_team_a_month_ago.id)).not_to be_nil
      end
    end
  end

  describe '#asleep?' do
    context 'default' do
      let(:team) { Fabricate(:team, created_at: Time.now.utc) }

      it 'false' do
        expect(team.asleep?).to be false
      end
    end

    context 'team created two weeks ago' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }

      it 'is asleep' do
        expect(team.asleep?).to be true
      end
    end

    context 'team created two weeks ago and subscribed' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago, subscribed: true) }

      before do
        allow(team).to receive(:inform_subscribed_changed!)
        team.update_attributes!(subscribed: true)
      end

      it 'is not asleep' do
        expect(team.asleep?).to be false
      end

      it 'resets subscription_expired_at' do
        expect(team.subscription_expired_at).to be_nil
      end
    end

    context 'team created over two weeks ago' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago - 1.day) }

      it 'is asleep' do
        expect(team.asleep?).to be true
      end
    end

    context 'team created over two weeks ago and subscribed' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago - 1.day, subscribed: true) }

      it 'is not asleep' do
        expect(team.asleep?).to be false
      end
    end
  end

  describe '#subscription_expired!' do
    let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }

    before do
      expect(team).to receive(:inform_system!).with(team.subscribe_text)
      expect(team).to receive(:inform_team_owner!).with(team.subscribe_text)
      team.subscription_expired!
    end

    it 'sets subscription_expired_at' do
      expect(team.subscription_expired_at).not_to be_nil
    end

    context '(re)subscribed' do
      before do
        expect(team).to receive(:inform_system!).with(team.subscribed_text)
        expect(team).to receive(:inform_team_owner!).with(team.subscribed_text)
        team.update_attributes!(subscribed: true)
      end

      it 'resets subscription_expired_at' do
        expect(team.subscription_expired_at).to be_nil
      end
    end
  end

  context 'subscribed states' do
    let(:today) { DateTime.parse('2018/7/15 12:42pm') }
    let(:subscribed_team) { Fabricate(:team, subscribed: true) }
    let(:team_created_today) { Fabricate(:team, created_at: today) }
    let(:team_created_1_week_ago) { Fabricate(:team, created_at: (today - 1.week)) }
    let(:team_created_3_weeks_ago) { Fabricate(:team, created_at: (today - 3.weeks)) }

    before do
      Timecop.travel(today + 1.day)
    end

    after do
      Timecop.return
    end

    it 'subscription_expired?' do
      expect(subscribed_team.subscription_expired?).to be false
      expect(team_created_1_week_ago.subscription_expired?).to be false
      expect(team_created_3_weeks_ago.subscription_expired?).to be true
    end

    it 'trial_ends_at' do
      expect { subscribed_team.trial_ends_at }.to raise_error 'Team is subscribed.'
      expect(team_created_today.trial_ends_at).to eq team_created_today.created_at + 2.weeks
      expect(team_created_1_week_ago.trial_ends_at).to eq team_created_1_week_ago.created_at + 2.weeks
      expect(team_created_3_weeks_ago.trial_ends_at).to eq team_created_3_weeks_ago.created_at + 2.weeks
    end

    it 'remaining_trial_days' do
      expect { subscribed_team.remaining_trial_days }.to raise_error 'Team is subscribed.'
      expect(team_created_today.remaining_trial_days).to eq 13
      expect(team_created_1_week_ago.remaining_trial_days).to eq 6
      expect(team_created_3_weeks_ago.remaining_trial_days).to eq 0
    end

    describe '#inform_trial!' do
      it 'subscribed' do
        expect(subscribed_team).not_to receive(:inform_system!)
        expect(subscribed_team).not_to receive(:inform_team_owner!)
        subscribed_team.inform_trial!
      end

      it '1 week ago' do
        expect(team_created_1_week_ago).to receive(:inform_system!).with(
          "Your trial subscription expires in 6 days. #{team_created_1_week_ago.subscribe_text}"
        )
        expect(team_created_1_week_ago).to receive(:inform_team_owner!).with(
          "Your trial subscription expires in 6 days. #{team_created_1_week_ago.subscribe_text}"
        )
        team_created_1_week_ago.inform_trial!
      end

      it 'expired' do
        expect(team_created_3_weeks_ago).not_to receive(:inform_system!)
        expect(team_created_3_weeks_ago).not_to receive(:inform_team_owner!)
        team_created_3_weeks_ago.inform_trial!
      end

      it 'informs once' do
        expect(team_created_1_week_ago).to receive(:inform_system!).once
        expect(team_created_1_week_ago).to receive(:inform_team_owner!).once
        2.times { team_created_1_week_ago.inform_trial! }
      end
    end
  end

  describe '#destroy' do
    let!(:team) { Fabricate(:team) }
    let!(:user1) { Fabricate(:user, team:) }
    let!(:user2) { Fabricate(:user, team:, access_token: 'token', token_expires_at: Time.now + 1.day, token_type: 'Bearer') }

    it 'revokes access tokens' do
      allow(team).to receive(:users).and_return([user1, user2])
      expect(user1).to receive(:revoke_access_token!)
      expect(user2).to receive(:revoke_access_token!)
      team.destroy
    end
  end

  describe '#deactivate!' do
    let!(:team) { Fabricate(:team) }

    it 'sets active to false' do
      expect(team.active).to be true
      team.deactivate!
      expect(team.active).to be false
    end
  end

  describe '#check_access!' do
    let(:team) { Fabricate(:team) }

    it 'deactivates a team on missing access' do
      allow(TeamsStrava::Bot.instance).to receive(:info).with(team.team_id).and_raise(TeamsStrava::Error, 'Missing Access (403)')
      expect(team).to receive(:deactivate!).and_call_original
      team.check_access!
      expect(team.active).to be false
    end
  end

  describe '#update_info!' do
    let(:team) { Fabricate(:team, team_name: 'Old Team Name') }

    it 'updates the team name from Teams' do
      team_info = Struct.new(:id, :name).new(team.team_id, 'Updated Team Name')
      allow(TeamsStrava::Bot.instance).to receive(:info).with(team.team_id).and_return(team_info)

      team.update_info!

      expect(team.team_name).to eq 'Updated Team Name'
    end
  end

  describe '#inform_team_owner!' do
    context 'team with an installer' do
      let(:team) { Fabricate(:team, installer_id: 'installer-id', tenant_id: 'tenant-id') }

      it 'returns the sent message metadata' do
        allow(TeamsStrava::Bot.instance).to receive(:send_dm)
          .with('installer-id', 'tenant-id', 'message')
          .and_return(Struct.new(:id, :conversation_id).new('m1', 'c1'))

        expect(team.team_owners).to eq ['installer-id']
        expect(team.inform_team_owner!('message')).to eq([{ activity_id: 'm1', conversation_id: 'c1' }])
      end
    end

    context 'team with no installer' do
      let(:team) { Fabricate(:team, installer_id: nil) }

      it 'returns nil' do
        expect(team.team_owners).to eq []
        expect(team.inform_team_owner!('message')).to be_nil
      end
    end

    context 'on a Teams error' do
      let(:team) { Fabricate(:team, installer_id: 'installer-id', tenant_id: 'tenant-id') }

      it 'skips failed owners' do
        allow(TeamsStrava::Bot.instance).to receive(:send_dm)
          .with('installer-id', 'tenant-id', 'message')
          .and_raise(TeamsStrava::Error, 'Missing Access (403)')

        expect(team.inform_team_owner!('message')).to eq []
      end
    end
  end

  describe '#inform_system!' do
    let(:team) { Fabricate(:team, conversation_id: 'conversation-id', service_url: 'https://smba.trafficmanager.net/amer/') }

    it 'sends a message to the team conversation' do
      allow(TeamsStrava::Bot.instance).to receive(:send_message)
        .with('conversation-id', 'https://smba.trafficmanager.net/amer/', 'message')
        .and_return(Struct.new(:id, :conversation_id).new('m1', 'conversation-id'))

      expect(team.inform_system!('message')).to eq(activity_id: 'm1', conversation_id: 'conversation-id')
    end

    it 'returns nil when there is no conversation' do
      team.set(conversation_id: nil)
      expect(team.inform_system!('message')).to be_nil
    end

    it 'logs a warning and returns nil on a Teams error' do
      allow(TeamsStrava::Bot.instance).to receive(:send_message)
        .and_raise(TeamsStrava::Error, 'Missing Access (403)')
      expect(team.inform_system!('message')).to be_nil
    end
  end

  describe '#prune_activities!' do
    before do
      allow_any_instance_of(Map).to receive(:save!)
    end

    let!(:team) { Fabricate(:team) }
    let!(:user) { Fabricate(:user, team: team) }
    let!(:team2) { Fabricate(:team) }
    let!(:user2) { Fabricate(:user, team: team2) }
    let!(:recent_activity) { Fabricate(:user_activity, user: user, updated_at: Time.now - 15.days) }
    let!(:old_activity) { Fabricate(:user_activity, user: user, updated_at: Time.now - 31.days) }
    let!(:very_old_activity) { Fabricate(:user_activity, user: user, updated_at: Time.now - 60.days) }
    let!(:other_team_activity) { Fabricate(:user_activity, team: team2, user: user2, updated_at: Time.now - 31.days) }

    it 'removes activities older than 30 days' do
      expect(team.activities.count).to eq 3
      expect {
        expect(team.prune_activities!).to eq 2
      }.to change(team.activities, :count).by(-2)
      expect(team.activities.count).to eq 1
      expect(team.activities.first).to eq recent_activity
    end

    context 'with a retention period of 45 days' do
      before do
        team.update_attributes!(retention: 45 * 24 * 60 * 60)
      end

      it 'removes older activities' do
        expect(team.activities.count).to eq 3
        expect {
          expect(team.prune_activities!).to eq 1
        }.to change(team.activities, :count).by(-1)
        expect(team.activities.count).to eq 2
        expect(team.activities.first).to eq recent_activity
      end
    end

    it 'does not affect other teams activities' do
      expect {
        team.prune_activities!
      }.not_to change(other_team_activity.team.activities, :count)
    end
  end

  describe '#retention' do
    context 'default value' do
      let(:team) { Fabricate(:team) }

      it 'sets default retention to 30 days in seconds' do
        expect(team.retention).to eq(30 * 24 * 60 * 60)
      end
    end

    context 'validation' do
      let(:team) { Fabricate(:team) }

      it 'allows valid retention periods' do
        [24 * 60 * 60, 7 * 24 * 60 * 60, 6 * 30 * 24 * 60 * 60].each do |retention|
          team.retention = retention
          expect(team).to be_valid
        end
      end

      it 'rejects retention less than 24 hours' do
        team.retention = 23 * 60 * 60
        expect(team).not_to be_valid
        expect(team.errors[:team]).to include('Retention must be at least 24 hours.')
      end

      it 'rejects retention more than 6 months' do
        team.retention = (6 * 30 * 24 * 60 * 60) + 1
        expect(team).not_to be_valid
        expect(team.errors[:team]).to include('Retention cannot exceed 6 months.')
      end

      it 'allows nil retention' do
        team.retention = nil
        expect(team).to be_valid
      end
    end
  end

  describe '#timezone' do
    let(:team) { Fabricate(:team) }

    it 'defaults to auto' do
      expect(team.timezone).to eq 'auto'
      expect(team.timezone_s).to eq 'auto (Eastern Time (US & Canada))'
    end

    it 'requires a timezone' do
      team.timezone = nil
      expect(team).not_to be_valid
      expect(team.errors[:timezone]).to include("can't be blank")
    end

    it 'detects timezone from activity data' do
      Fabricate(:user_activity, team: team, timezone: '(GMT-08:00) America/Los_Angeles')

      expect(team.detect_timezone.name).to eq 'Pacific Time (US & Canada)'
      expect(team.timezone_s).to eq 'auto (Pacific Time (US & Canada))'
    end

    it 'uses the most common recent activity timezone' do
      3.times { Fabricate(:user_activity, team: team, timezone: '(GMT-08:00) America/Los_Angeles') }
      Fabricate(:user_activity, team: team, timezone: '(GMT-05:00) America/New_York')

      expect(team.detect_timezone.name).to eq 'Pacific Time (US & Canada)'
    end

    it 'returns current time in the configured timezone' do
      team.timezone = 'Pacific Time (US & Canada)'

      Timecop.freeze(Time.utc(2026, 3, 19, 12, 0, 0)) do
        expect(team.now.zone).to eq 'PDT'
        expect(team.now.hour).to eq 5
      end
    end
  end

  describe '#max_activities_per_user_per_day' do
    let(:team) { Fabricate(:team) }

    it 'defaults to unlimited' do
      expect(team.max_activities_per_user_per_day).to be_nil
      expect(team.max_activities_per_user_per_day_s).to eq 'unlimited'
    end

    it 'formats configured values' do
      team.max_activities_per_user_per_day = 5
      expect(team.max_activities_per_user_per_day_s).to eq '5 per day'
    end

    it 'rejects values less than 1' do
      team.max_activities_per_user_per_day = 0
      expect(team).not_to be_valid
      expect(team.errors[:team]).to include('Max activities per user per day must be at least 1.')
    end
  end

  describe '#max_activities_per_channel_per_day' do
    let(:team) { Fabricate(:team) }

    it 'defaults to unlimited' do
      expect(team.max_activities_per_channel_per_day).to be_nil
      expect(team.max_activities_per_channel_per_day_s).to eq 'unlimited'
    end

    it 'formats configured values' do
      team.max_activities_per_channel_per_day = 10
      expect(team.max_activities_per_channel_per_day_s).to eq '10 per day'
    end

    it 'rejects values less than 1' do
      team.max_activities_per_channel_per_day = 0
      expect(team).not_to be_valid
      expect(team.errors[:team]).to include('Max activities per channel per day must be at least 1.')
    end
  end
end
