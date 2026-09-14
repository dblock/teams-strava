$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV.fetch('RACK_ENV', nil)

require 'teams-strava'

NewRelic::Agent.manual_start

TeamsStrava::App.instance.prepare!

Thread.abort_on_exception = true

Thread.new do
  TeamsStrava::Service.instance.start_from_database!
  TeamsStrava::App.instance.after_start!
end

run Api::Middleware.instance
