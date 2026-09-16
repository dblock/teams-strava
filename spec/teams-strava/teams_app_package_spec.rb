require 'spec_helper'

describe TeamsStrava::TeamsAppPackage do
  before do
    Api::Middleware.cache.clear
  end

  describe '.zip' do
    let(:zip_bytes) { described_class.zip }

    def entries(bytes)
      entries = []
      Zip::InputStream.open(StringIO.new(bytes)) do |io|
        while (entry = io.get_next_entry)
          entries << entry.name
        end
      end
      entries
    end

    it 'builds a zip containing the manifest and icons' do
      expect(entries(zip_bytes)).to contain_exactly('manifest.json', 'color.png', 'outline.png')
    end

    it 'includes the current manifest.json contents' do
      manifest_path = File.expand_path('../../manifest/manifest.json', __dir__)
      Zip::InputStream.open(StringIO.new(zip_bytes)) do |io|
        while (entry = io.get_next_entry)
          next unless entry.name == 'manifest.json'

          expect(entry.get_input_stream.read).to eq File.binread(manifest_path)
        end
      end
    end

    it 'caches the built zip' do
      expect(described_class).to receive(:build_zip).once.and_call_original
      2.times { described_class.zip }
    end
  end
end
