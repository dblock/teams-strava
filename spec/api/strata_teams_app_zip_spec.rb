require 'spec_helper'

describe Api do
  include Api::Test::EndpointTest

  it 'serves the Teams app package zip' do
    get '/strata-teams-app.zip'
    expect(last_response.status).to eq 200
    expect(last_response.headers['Content-Type']).to eq 'application/zip'
    expect(last_response.headers['Content-Disposition']).to eq 'attachment; filename="strata-teams-app.zip"'
    expect(last_response.body).to eq TeamsStrava::TeamsAppPackage.zip
  end
end
