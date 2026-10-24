require 'spec_helper'

describe 'Help', :js, type: :feature do
  it 'keeps the ribbon background fixed when command help expands' do
    visit '/help.html'
    background = '(() => { const style = getComputedStyle(document.body, "::before"); return [style.position, style.width, style.height]; })()'
    original_background = page.evaluate_script(background)
    original_height = page.evaluate_script('document.documentElement.scrollHeight')

    find('summary', text: 'Sharing and privacy').click

    expect(page).to have_css('details[open]', text: '@Strata set private true')
    expect(page.evaluate_script('document.documentElement.scrollHeight')).to be > original_height
    expect(original_background.first).to eq 'fixed'
    expect(page.evaluate_script(background)).to eq original_background
  end
end
