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
      expect(title).to eq('Strata')
      expect(page).to have_css('h1', exact_text: 'Strata')
      expect(page).to have_no_css('h1 + p', exact_text: 'Powered by Strava')
      expect(page).to have_css('meta[property="og:title"][content="Strata"]', visible: :hidden)
      expect(page).to have_css('meta[name="twitter:title"][content="Strata"]', visible: :hidden)
    end

    it 'includes links to install the Teams app' do
      install_links = all("a[href='https://teams.example/install']")
      expect(install_links.size).to eq(2)
      expect(install_links.map(&:text)).to all(eq('Add to Microsoft Teams'))
    end

    it 'loads the transparent logo and original Teams activity screenshot in the hero' do
      expect(page).to have_css('.hero-preview img[alt*="marathon activity"]')
      expect(page.evaluate_script('document.querySelector(".hero-preview img").naturalWidth')).to eq(1366)
      alphas = page.evaluate_script(<<~JS)
        (() => {
          return Array.from(document.querySelectorAll(".hero-logo, .hero-preview img")).map(image => {
            const canvas = document.createElement("canvas");
            canvas.width = image.naturalWidth;
            canvas.height = image.naturalHeight;
            const context = canvas.getContext("2d");
            context.drawImage(image, 0, 0);
            return context.getImageData(0, 0, 1, 1).data[3];
          });
        })()
      JS
      expect(alphas).to eq([0, 0])
    end

    it 'fits the page and screenshot on a narrow screen' do
      original_size = page.current_window.size
      page.current_window.resize_to(390, 844)

      expect(page).to have_link('Get started', href: '/help.html#get-started')
      expect(page.evaluate_script('document.documentElement.scrollWidth')).to be <= page.evaluate_script('window.innerWidth')
    ensure
      page.current_window.resize_to(*original_size)
    end
  end
end
