require 'spec_helper'

describe 'Teams', :js, type: :feature do
  before do
    ENV['TEAMS_APP_INSTALL_URL'] = 'https://teams.example/install'
  end

  after do
    ENV.delete 'TEAMS_APP_INSTALL_URL'
  end

  context 'obsolete oauth callback params' do
    it 'does not register a team and still shows the install flow' do
      expect {
        visit '/?code=code&guild_id=guild_id&permissions=2147502080'

        expect(title).to eq('Strata: Strava integration with Microsoft Teams')
        expect(page).to have_no_text('Team successfully registered!')
        expect(all("a[href='https://teams.example/install']").size).to eq(2)
      }.not_to change(Team, :count)
    end
  end
end
