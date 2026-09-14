RSpec.configure do |config|
  config.before do
    TeamsStrava::Bot.reset!
    ENV['CLIENT_ID'] = 'client_id'
    ENV['CLIENT_SECRET'] = 'client_secret'
    ENV['TENANT_ID'] = 'tenant_id'
  end
end
