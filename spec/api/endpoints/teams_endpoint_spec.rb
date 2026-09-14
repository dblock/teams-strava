require 'spec_helper'

describe Api::Endpoints::TeamsEndpoint do
  include Api::Test::EndpointTest

  context 'teams' do
    subject(:teams) { client.teams }

    it 'lists no teams' do
      expect(teams.to_a.size).to eq 0
    end

    context 'with teams' do
      let!(:team1) { Fabricate(:team, api: false) }
      let!(:team2) { Fabricate(:team, api: true) }

      it 'lists teams with api enabled' do
        expect(teams.to_a.size).to eq 1
        expect(teams.first.id).to eq team2.id.to_s
      end

      it 'gets an api-enabled team' do
        team = client.team(id: team2.id)
        expect(team.id).to eq team2.id.to_s
        expect(team.team_id).to eq team2.team_id
        expect(team.team_name).to eq team2.team_name
      end

      it 'does not get a team with api disabled' do
        get "/api/teams/#{team1.id}"

        expect(last_response.status).to eq 404
        expect(JSON.parse(last_response.body)).to eq('error' => 'Not Found')
      end
    end
  end

  context 'team creation' do
    it 'requires code' do
      expect { client.teams._post }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['message']).to eq 'Invalid parameters.'
        expect(json['type']).to eq 'param_error'
      end
    end

    it 'returns gone because teams are created from conversation updates' do
      post '/api/teams', {
        code: 'code',
        guild_id: 'obsolete-guild-id',
        permissions: 1_234_567
      }

      expect(last_response.status).to eq 410
      expect(JSON.parse(last_response.body)).to eq(
        'error' => 'Teams are created automatically when the bot is installed.'
      )
    end
  end
end
