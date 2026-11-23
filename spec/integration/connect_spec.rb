require 'spec_helper'

describe 'Connect', :js, type: :feature do
  let(:user) { Fabricate(:user) }

  before do
    allow_any_instance_of(User).to receive(:dm!)
  end

  it 'explains a canceled Strava authorization' do
    visit "/connect?state=#{user.id}&error=access_denied"
    expect(find_by_id('messages')).to have_text('Strava authorization was canceled, so your account was not connected.')
    expect(find_by_id('messages')).to have_text('Send @Strata connect in your Teams channel')
  end

  it 'explains an invalid or expired link' do
    visit '/connect?state=invalid&code=code'
    expect(find_by_id('messages')).to have_text('This connect link is invalid or has expired.')
  end

  it 'explains a missing authorization code' do
    visit "/connect?state=#{user.id}"
    expect(find_by_id('messages')).to have_text('Strava did not return an authorization code.')
  end

  it 'explains a missing activity permission' do
    visit "/connect?state=#{user.id}&code=code&scope=read"
    expect(find_by_id('messages')).to have_text('Strata needs permission to view your activities')
    expect(user.reload.access_token).to be_nil
  end

  it 'does not execute script from request parameters' do
    injected = CGI.escape('"</script><script>window.injected=true</script>')
    visit "/connect?state=#{user.id}&code=#{injected}&error=#{injected}"
    expect(find_by_id('messages')).to have_text('Strava could not authorize Strata')
    expect(page.evaluate_script('window.injected')).to be_nil
  end

  it 'connects even when posting to the Teams channel fails', vcr: { cassette_name: 'strava/retrieve_access', allow_playback_repeats: true } do
    allow_any_instance_of(User).to receive(:inform!).and_raise(TeamsStrava::Error, 'Forbidden (403)')
    visit "/connect?state=#{user.id}&code=code&scope=read,activity:read_all"
    expect(find_by_id('messages')).to have_text("Successfully connected #{user.user_name} to Strava.")
    expect(user.reload.access_token).to eq 'token'
  end
end
