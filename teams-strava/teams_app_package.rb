module TeamsStrava
  # Builds the Teams app package (manifest.json + icons) as a zip, ready to
  # be sideloaded via Teams Admin Center. The package is small and cheap to
  # rebuild, but is cached (like Map#cached_png) so we don't re-zip it on
  # every request.
  class TeamsAppPackage
    MANIFEST_DIR = File.expand_path('../manifest', __dir__).freeze
    FILES = %w[manifest.json color.png outline.png].freeze
    CACHE_KEY = 'teams-app-package.zip'.freeze

    def self.zip
      Api::Middleware.cache.read(CACHE_KEY) || begin
        body = build_zip
        Api::Middleware.cache.write(CACHE_KEY, body)
        body
      end
    end

    def self.build_zip
      buffer = Zip::OutputStream.write_buffer do |zip|
        FILES.each do |file|
          zip.put_next_entry(file)
          zip.write File.binread(File.join(MANIFEST_DIR, file))
        end
      end
      buffer.string
    end
  end
end
