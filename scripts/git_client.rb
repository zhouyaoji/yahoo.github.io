#! /usr/bin/env ruby

require './lib/creds'
require './lib/git_api'

=begin 
This is a client app for making REST calls
to the Git API. The credentials can
be provided on the command line or read
from file. After you run the command
once, your credentials will be available
from file.
=end

def die (msg, err_code)
  puts msg
  exit err_code
end

# Handle command-line options
options = {}
usage_msg = "Usage: git_client.rb [options] [<username> <password>]"

opts = OptionParser.new do |o|
  options[:form] = "medium"
  o.banner = usage_msg
  o.separator " "
  o.on('-f', 'Creates a CSV file with results.') { |f| options[:file] = true;}
  o.on('-s', 'Displays short-form results.') { |s| options[:form] = "short" }
  o.on('-m', 'Displays medium-form results (default).') { |m| options[:form] = "medium" }
  o.on('-l', 'Displays medium-form results.') { |l| options[:form] = "long" }
  o.on('-r', 'Displays teams and their repos.') { |t| options[:repos] = true }
  o.on('-t', 'Displays teams with their members.') { |t| options[:teams] = true }
  o.on('-p', 'Displays only public information.') { |p| options[:public] = true }
  o.on('-h', "Shows this help menu.") { puts o; exit }
end.parse!

al = ARGV.size
c = Creds.new
if al == 2
   un = ARGV[0]
   pw = ARGV[1]
   c.username = un
   c.password = pw
   if File.file? Creds::CREDS_FILE
     `rm .creds`
   end
   c.write_creds
elsif File.file? Creds::CREDS_FILE
   creds = c.get_creds
   un = "#{creds[0]}"
   pw = "#{creds[1]}"
else 
  puts "You need to provide credentials on the command line or in the file '.creds'."
  die usage_msg, 1
end
if not options[:public].nil? and options[:public] == true
  type = "type=public" 
else 
  type = "type=all"
end
git = GitApi.new(un, pw)
if options[:repos]
  git.list_repos_of_teams("yahoo", type)
  exit
end
if options[:teams]
  git.list_members_of_teams("yahoo", type)
  exit
end
git.get_data("yahoo", type)
git.display(options[:form])
if(options[:file]) 
  git.create_csv
end
