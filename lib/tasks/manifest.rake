namespace :manifest do
  desc 'Build the Teams app package zip into store/pkg/'
  task :package do
    require 'fileutils'
    require 'zip'
    require_relative '../../teams-strava/teams_app_package'

    FileUtils.mkdir_p('store/pkg')
    path = File.join('store', 'pkg', 'strata-teams-app.zip')
    File.binwrite(path, TeamsStrava::TeamsAppPackage.build_zip)
    puts "Wrote #{path}"
  end
end
