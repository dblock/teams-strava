module Api
  class Middleware
    def self.logger
      @logger ||= begin
        $stdout.sync = true
        Logger.new($stdout)
      end
    end

    def self.cache
      @cache ||= begin
        tmp_dir = File.join(Dir.tmpdir, 'teams-strava')
        # TODO: use an LRU with a max size
        # on DigitalOcean a filled up temporary storage causes the container to be recycled
        logger.info "Initializing file cache in #{tmp_dir}."
        ActiveSupport::Cache::FileStore.new(tmp_dir)
      end
    end

    def self.instance
      @instance ||= Rack::Builder.new {
        use Rack::Cors do
          allow do
            origins '*'
            resource '*', headers: :any, methods: %i[get post]
          end
        end

        # rewrite HAL links to make them clickable in a browser
        use Rack::Rewrite do
          r302 %r{(/[\w/]*/)(%7B|\{)?(.*)(%7D|\})}, '$1'
        end

        use Rack::ContentLength
        use Rack::ConditionalGet
        use Rack::ETag
        use Rack::Robotz, 'User-Agent' => '*', 'Disallow' => '/api', 'Sitemap' => "#{TeamsStrava::Service.url}/sitemap.xml"
        use Rack::ServerPages

        map '/api/messages' do
          run lambda { |env|
            # Rack::Builder#map strips the mounted prefix from PATH_INFO
            # (moving it to SCRIPT_NAME), but teams_rb's rack app matches
            # requests by their full, un-stripped path. Restore it before
            # handing off.
            env['PATH_INFO'] = '/api/messages'
            body = env['rack.input'].read.to_s
            env['rack.input'] = StringIO.new(body)
            Api::Middleware.logger.info "[bot] #{env['REQUEST_METHOD']} #{env['PATH_INFO']}: #{body}"
            TeamsStrava::Bot.instance.to_rack.call(env)
          }
        end

        map '/' do
          run Api::Middleware.new
        end
      }.to_app
    end

    def call(env)
      Api::Endpoints::RootEndpoint.call(env)
    end
  end
end
