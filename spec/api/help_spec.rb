require 'spec_helper'
require 'nokogiri'

describe Api do
  include Api::Test::EndpointTest

  context 'help and onboarding' do
    it 'uses the shared layout and favicon on every HTML page' do
      %w[/ /help.html /privacy.html /terms.html /connect.html /subscribe.html /update_cc.html].each do |path|
        get path

        expect(last_response.status).to eq 200
        document = Nokogiri::HTML(last_response.body)
        expect(document.at_css('body.site-page > nav[aria-label="Main navigation"]')).not_to be_nil
        expect(document.at_css('main#main')).not_to be_nil
        expect(document.at_css('body > footer.site-footer')).not_to be_nil
        expect(document.at_css('link[rel="icon"]')['href']).to eq '/favicon.ico?v=blue'
      end
    end

    it 'provides sign-up and installation links' do
      get '/help.html'

      expect(last_response.status).to eq 200
      document = Nokogiri::HTML(last_response.body)
      expect(document.css('#get-started a').map { |link| link['href'] }).to include(
        'https://www.strava.com/register',
        TeamsStrava::Service.install_url
      )
    end

    it 'explains how to stop sharing and contact support' do
      get '/help.html'

      document = Nokogiri::HTML(last_response.body)
      expect(document.at_css('#get-started').text).to include('@Strata disconnect', 'does not remove activity cards')
      expect(document.at_css('#support a')['href']).to eq 'mailto:dblock@vestris.com'
    end

    it 'groups command help into expandable topics without the outdated screenshot' do
      get '/help.html'

      document = Nokogiri::HTML(last_response.body)
      expect(document.css('#commands details summary').map(&:text)).to include('Sharing and privacy', 'Units, maps, and fields')
      expect(document.css('img[src$="help.png"]')).to be_empty
    end

    it 'serves the local destinations linked from the manifest description' do
      manifest_path = File.expand_path('../../manifest/manifest.json', __dir__)
      description = JSON.parse(File.read(manifest_path)).fetch('description').fetch('full')
      links = description.scan(%r{https://strata\.playplay\.io/[^)\s]+}).map { |url| URI.parse(url) }
      expect(links.map(&:fragment)).to include('get-started', 'support')

      links.each do |link|
        get link.path
        expect(last_response.status).to eq 200
        next unless link.fragment

        expect(Nokogiri::HTML(last_response.body).at_css("##{link.fragment}")).not_to be_nil
      end
    end
  end
end
