require 'spec_helper'

describe TeamsStrava::Commands::Disconnect do
  context 'self' do
    include_context 'teams command' do
      let(:args) { ['disconnect'] }
    end
    context 'disconnect' do
      # Beta: free for everyone, subscription enforcement disabled.
      it 'works without a subscription' do
        expect(response).to eq 'Strava account is not connected.'
      end

      context 'subscribed team' do
        let(:team) { Fabricate(:team, subscribed: true) }

        context 'connected user' do
          let(:user) { Fabricate(:user, team:, access_token: 'token', token_type: 'Bearer') }

          it 'disconnects a user' do
            expect_any_instance_of(User).to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).to receive(:deauthorize).and_return(Hashie::Mash.new(access_token: 'token'))
            expect(response).to eq 'Strava account successfully disconnected.'
            user.reload
            expect(user.access_token).to be_nil
            expect(user.connected_to_strava_at).to be_nil
            expect(user.token_type).to be_nil
          end
        end

        context 'disconnected user' do
          let(:user) { Fabricate(:user, team:) }

          it 'fails to disconnect a user' do
            expect(response).to eq 'Strava account is not connected.'
          end
        end
      end

      context 'unsubscribed team' do
        context 'connected user' do
          let(:user) { Fabricate(:user, team:, access_token: 'token', token_type: 'Bearer') }

          # Beta: free for everyone, subscription enforcement disabled.
          it 'disconnects a user' do
            expect_any_instance_of(User).to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).to receive(:deauthorize).and_return(Hashie::Mash.new(access_token: 'token'))
            expect(response).to eq 'Strava account successfully disconnected.'
          end
        end
      end
    end
  end

  context 'another connected user' do
    let(:another_user) { Fabricate(:user, team:, user_name: 'another user', access_token: 'token', token_type: 'Bearer', connected_to_strava_at: Time.now.utc) }

    include_context 'teams command' do
      let(:args) { ['disconnect', another_user.user_name] }
    end

    before { another_user }

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'disconnect' do
        context 'admin' do
          before do
            allow_any_instance_of(User).to receive(:team_owner?).and_return(true)
          end

          it 'disconnects the user' do
            expect_any_instance_of(User).to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).to receive(:deauthorize).and_return(Hashie::Mash.new(access_token: 'token'))
            expect(response).to eq "Strava account for user #{another_user.teams_mention} successfully disconnected."
            another_user.reload
            expect(another_user.access_token).to be_nil
            expect(another_user.connected_to_strava_at).to be_nil
            expect(another_user.token_type).to be_nil
          end
        end

        context 'not an admin' do
          before do
            allow_any_instance_of(User).to receive(:team_owner?).and_return(false)
          end

          it 'does not disconnect the user' do
            expect_any_instance_of(User).not_to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).not_to receive(:deauthorize)
            expect(response).to eq 'Sorry, only a team owner can disconnect other users.'
            another_user.reload
            expect(another_user.access_token).not_to be_nil
            expect(another_user.connected_to_strava_at).not_to be_nil
            expect(another_user.token_type).not_to be_nil
          end
        end
      end
    end
  end

  context 'an invalid user' do
    include_context 'teams command' do
      let(:args) { %w[disconnect invalid] }
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'disconnect' do
        context 'admin' do
          before do
            allow_any_instance_of(User).to receive(:team_owner?).and_return(true)
          end

          it 'cannot disconnect the user' do
            expect_any_instance_of(User).not_to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).not_to receive(:deauthorize)
            expect(response).to eq 'I cannot find the user invalid, sorry.'
          end
        end
      end
    end
  end

  context 'a user in another team' do
    let(:another_team) { Fabricate(:team) }
    let(:another_user) { Fabricate(:user, team: another_team, user_name: 'another user', access_token: 'token', token_type: 'Bearer', connected_to_strava_at: Time.now.utc) }

    include_context 'teams command' do
      let(:args) { ['disconnect', another_user.user_name] }
    end

    before { another_user }

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'disconnect' do
        context 'admin' do
          before do
            allow_any_instance_of(User).to receive(:team_owner?).and_return(true)
          end

          it 'cannot disconnect the user' do
            expect_any_instance_of(User).not_to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).not_to receive(:deauthorize)
            expect(response).to eq "I cannot find the user #{another_user.user_name}, sorry."
            another_user.reload
            expect(another_user.access_token).not_to be_nil
            expect(another_user.connected_to_strava_at).not_to be_nil
            expect(another_user.token_type).not_to be_nil
          end
        end
      end
    end
  end
end
