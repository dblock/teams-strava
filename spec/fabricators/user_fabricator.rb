Fabricator(:user) do
  user_id { Fabricate.sequence(:user_id) { |i| "user-#{i}" } }
  user_name { Faker::Internet.username }
  channel_id { Fabricate.sequence(:channel_id) { |i| "channel-#{i}" } }
  service_url { 'https://smba.trafficmanager.net/amer/' }
  team { Team.first || Fabricate(:team) }
  athlete { |user| Fabricate.build(:athlete, user:) }
end
