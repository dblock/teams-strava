require 'spec_helper'

describe TeamsStrava::Service do
  describe '#url' do
    before do
      @rack_env = ENV.fetch('RACK_ENV', nil)
    end

    after do
      ENV['RACK_ENV'] = @rack_env
    end

    it 'defaults to playplay.io in production' do
      expect(described_class.url).to eq 'https://strata.playplay.io'
    end

    context 'in development' do
      before do
        ENV['RACK_ENV'] = 'development'
      end

      it 'defaults to localhost' do
        expect(described_class.url).to eq 'http://localhost:5000'
      end
    end

    context 'when set' do
      before do
        ENV['URL'] = 'updated'
      end

      after do
        ENV.delete('URL')
      end

      it 'defaults to ENV' do
        expect(described_class.url).to eq 'updated'
      end
    end
  end

  describe '#install_url' do
    it 'defaults to the app package download link' do
      expect(described_class.install_url).to eq "#{described_class.url}/strata-teams-app.zip"
    end

    context 'with TEAMS_APP_ID' do
      before do
        ENV['TEAMS_APP_ID'] = 'app-guid'
      end

      after do
        ENV.delete('TEAMS_APP_ID')
      end

      it 'returns a Teams install deep link' do
        expect(described_class.install_url).to eq 'https://teams.microsoft.com/l/app/app-guid'
      end
    end

    context 'with TEAMS_APP_INSTALL_URL' do
      before do
        ENV['TEAMS_APP_ID'] = 'app-guid'
        ENV['TEAMS_APP_INSTALL_URL'] = 'https://example.com/install'
      end

      after do
        ENV.delete('TEAMS_APP_ID')
        ENV.delete('TEAMS_APP_INSTALL_URL')
      end

      it 'takes precedence over TEAMS_APP_ID' do
        expect(described_class.install_url).to eq 'https://example.com/install'
      end
    end
  end
end
