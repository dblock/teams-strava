# Usage (from a production dyno/shell, with production env vars loaded):
#   bundle exec ruby -I . -r teams-strava script/verify_production.rb
#
# Sanity-checks that a production deployment is wired up correctly: required
# env vars are present, the bot can authenticate with Bot Framework, Stripe
# has the expected plan/price, and MongoDB is reachable. Exits non-zero (and
# prints what's wrong) on any failure, so it's suitable for CI/health checks.

failures = []

def check(label)
  print "#{label}... "
  yield
  puts 'OK'
rescue StandardError => e
  puts "FAILED (#{e.class}: #{e.message})"
  raise
end

# 1. Required environment variables.
%w[
  CLIENT_ID CLIENT_SECRET TENANT_ID
  STRAVA_CLIENT_ID STRAVA_CLIENT_SECRET
  STRIPE_API_KEY STRIPE_API_PUBLISHABLE_KEY
  MONGO_URL
].each do |var|
  check("ENV['#{var}'] present") { raise "missing #{var}" if ENV[var].to_s.empty? }
rescue StandardError
  failures << var
end

# 2. Bot Framework auth (acquires a real client-credentials token).
begin
  check('Bot Framework client-credentials auth') do
    TeamsStrava::Bot.instance.app.initialize!
  end
rescue StandardError
  failures << 'bot auth'
end

# 3. Stripe: plan/price exists and matches the expected amount.
begin
  expected_amount = 2499 # $24.99
  check("Stripe plan 'strata-yearly' amount == $#{format('%.2f', expected_amount / 100.0)}") do
    plan = Stripe::Plan.retrieve('strata-yearly')
    raise "found amount=#{plan.amount}, expected #{expected_amount}" unless plan.amount == expected_amount
  end
rescue StandardError
  failures << 'stripe plan'
end

# 4. MongoDB connectivity.
begin
  check('MongoDB connectivity (Team.count)') { Team.count }
rescue StandardError
  failures << 'mongodb'
end

# 5. Strava auth: STRAVA_CLIENT_ID/STRAVA_CLIENT_SECRET are validated
# server-side (no user token needed) by listing push subscriptions.
begin
  check('Strava client_id/client_secret auth (list push subscriptions)') do
    StravaWebhook.instance.client.push_subscriptions
  end
rescue StandardError
  failures << 'strava auth'
end

if failures.any?
  warn "\nFAILED: #{failures.join(', ')}"
  exit 1
end

puts "\nAll checks passed."
