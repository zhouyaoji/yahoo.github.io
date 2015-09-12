require 'yard'
require 'rake/testtask'

desc "Build package: rake build[<user>,<host>]"
task :build, [:user, :host] do |t, a| 
  sh "tar -czf yahoo_git.tar.gz  _site"
  sh "scp ./yahoo_git.tar.gz #{a[:user]}@#{a[:host]}:~"
end

desc "Build documentation."
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']   # optional
  t.options = ['--any', '--extra', '--opts'] # optional
end

desc "Clean up."
task :clean do
  sh "rm -rf _site"
  sh "rm .*gz"
  sh "rm \*\.swp"
  sh "rm _data/*csv"
end
namespace :data do
  desc "Get repos data"
  task :repo do
    ruby "scripts/git_client.rb -r"
    sh "mv yahoo_team_repos.csv _data"
  end
  desc "Get team members data"
  task :team do
    ruby "scripts/git_client.rb -t"
    sh "mv yahoo_team_members.csv _data"
  end
  desc "Get general Git data."
  task :general do
    ruby "scripts/git_client.rb -f"
    sh "mv yahoo_git.csv _data"
  end
  desc "Get public repos data"
  task :public_repo do
    ruby "scripts/git_client.rb -f -p"
    sh "mv yahoo_git.csv _data/public_yahoo_git.csv"
  end
  desc "Sort the Git stats"
  task :sort do
    ruby "scripts/sort_stats_by_watchers.rb"
  end
end
