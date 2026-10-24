require 'spec_helper'
require 'nokogiri'

describe Api do
  include Api::Test::EndpointTest

  context 'help and onboarding' do
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
