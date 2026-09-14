require 'spec_helper'

describe 'Homepage', :js, type: :feature do
  before do
    ENV['TEAMS_APP_INSTALL_URL'] = 'https://teams.example/install'
  end

  after do
    ENV.delete 'TEAMS_APP_INSTALL_URL'
  end

  context 'homepage' do
    before do
      visit '/'
    end

    it 'displays index.html page' do
      expect(title).to eq('Strata: Strava integration with Microsoft Teams')
    end

    it 'includes links to install the Teams app' do
      expect(all("a[href='https://teams.example/install']").size).to eq(2)
    end
  end
end
