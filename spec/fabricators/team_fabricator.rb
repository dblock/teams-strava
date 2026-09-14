Fabricator(:team) do
  team_id { Fabricate.sequence(:team_id) { |i| "team-#{i}" } }
  tenant_id { Fabricate.sequence(:tenant_id) { |i| "tenant-#{i}" } }
  conversation_id { Fabricate.sequence(:conversation_id) { |i| "conversation-#{i}" } }
  service_url { 'https://smba.trafficmanager.net/amer/' }
  installer_id { Fabricate.sequence(:installer_id) { |i| "user-#{i}" } }
  installer_name { Faker::Internet.username }
  team_name { Faker::Lorem.word }
  api { true }
end
