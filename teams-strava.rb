ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV.fetch('RACK_ENV', nil)

Dir["#{File.expand_path('config/initializers', __dir__)}/**/*.rb"].each do |file|
  require file
end

Mongoid.load! File.expand_path('config/mongoid.yml', __dir__), ENV.fetch('RACK_ENV', nil)

require 'teams-strava/version'
require 'teams-strava/config'
require 'teams-strava/loggable'
require 'teams-strava/card_renderer'
require 'teams-strava/bot'
require 'teams-strava/service'
require 'teams-strava/info'
require 'teams-strava/models'
require 'teams-strava/api'
require 'teams-strava/app'
require 'teams-strava/server'
require 'teams-strava/commands'
