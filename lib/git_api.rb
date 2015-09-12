require 'net/http'
require 'json'
require 'optparse'
require 'tempfile'
require 'openssl'
require 'base64'
require 'optparse/time'
require 'ostruct'
require 'pp'
require 'csv'

# @author Joseph Catera
# The GitApi class allows you to make calls to the GitHub API
# and create CSV files with the response data.

class GitApi

  @@base_url = "https://api.github.com/"
  @@titles = ["Members", "Teams", "Repos"]
  @@headings = { login: "Login Name",
                 html_url: "User URL", 
                 organizations_url: "Organizational URLs", 
                 repos_url: "Repositories URL", 
                 description: "Team Description", 
                 members_url: "Members URL", 
                 repo_name: "Repository Name", 
                 repo_url: "Repository URL", 
                 repositories_url: "Repository URL", 
                 team_name: "Team Name", 
                 teams_url: "Team URL",
                 updated_at: "Last Update",
                 stargazers_count: "Stargazers Count", 
                 watchers_count: "Watchers Count", 
                 forks_count: "Forks Count", 
                 open_issues_count: "Open Issues Count",
                 git_url: "Git URL",
                 repo_desc: "Repository Description",
                 language: "Language"
               }

   # @!method def initialize(username,password)
   # Sets GitHub credentials and defines headers for CSV file.
   # @param username [String] The GitHub username.
   # @param password [String] The GitHub password.
   # @return None
  def initialize(username,password)
      @username = URI.escape(username)
      @password = URI.escape(password)
      @members = []
      @teams = []
      @repos = []
      @data = []
      @csv = ""
      @csv_headers = [@@headings[:repo_name],@@headings[:repo_url],@@headings[:teams_url],@@headings[:updated_at],@@headings[:watchers_count],@@headings[:forks_count],@@headings[:open_issues_count], @@headings[:language]]
  end
  # @!method get_data(org, qs="role=admin")
  # Adds the members, teams, and repos for an organization based on a particular role to the @data array.
  # @param org [String] The GitHub organization. 
  # @param qs [String] The query string to append to resource URI. The default is "role=admin". 
  # @return None
  # @note The response from `get_members`, `get_teams`, and `get_repos` are added to the @data array.
  def get_data(org, qs="role=admin")
     get_members(org, qs)
     get_teams(org, qs)
     get_repos(org, qs) 
     @data.push(@members,@teams,@repos)
  end 
  # @!method list_members_of_teams(org, qs)
  # Displays the results in one of three formats: long, short, or medium.
  # (see #display_short, #display_long, and #display_medium)
  # @param form [String] The format that you want displayed.
  # @return None
  # @note The results are displayed to standard output.
  def display(form)
     if form == "long"
         display_long
     elsif form == "short"
         display_short
     else
         display_medium
     end
  end
  # @!method list_members_of_teams(org, qs)
  # Displays the members of a team for an organization.
  # @param org [String] The GitHub organization.
  # @param qs [String] The query string.
  # @return None
  # @note The results are displayed to standard output and written to the CSV file `yahoo_team_members.csv`.
  def list_members_of_teams(org, qs)
    get_teams(org, qs)
    @csv += header_row([@@headings[:repo_name],@@headings[:html_url], @@headings[:organizations_url], @@headings[:repos_url]])
    @teams.each do |arr|
      arr.each_with_index do |a, i|
        id = arr[i]["id"]
        title = arr[i]["name"]
        uri = @@base_url + "teams/" + id.to_s + "/members"
        members = make_call(uri, qs)
        @csv += display_members(title, members)
      end
    end
    write_csv("yahoo_team_members.csv")
  end
  # @!method list_repos_of_teams(org, qs)
  # Displays the repos of the teams of an organization.
  # @param org [String] The GitHub organization.
  # @param qs [String] The query string.
  # @return None
  # @note The results are displayed to standard output and written to the CSV file `yahoo_team_repos.csv`.
  def list_repos_of_teams(org, qs)
    get_teams(org, qs)
    @csv += header_row([@@headings[:repo_name],@@headings[:repo_url], @@headings[:repo_desc], @@headings[:git_url], @@headings[:watchers_count], @@headings[:forks_count], @@headings[:open_issues_count], @@headings[:updated_at], @@headings[:language]])
    @teams.each do |arr|
      arr.each_with_index do |a, i|
        title = arr[i]["name"] 
        id = arr[i]["id"]
        uri = @@base_url + "teams/" + id.to_s + "/repos"
        repos = make_call(uri, qs)
        @csv += display_repos(title, repos)
      end
    end
    write_csv("yahoo_team_repos.csv")
  end
  # @!method create_csv(headers = @csv_headers, data = @repos, general = true, write=true, filename = 'yahoo_git.csv')
  # Displays the CSV file based on headers, the repos.
  # @param headers [Array<String>] The headers for the CSV file.
  # @param data [Array<Hash{String => Hash{String => String}}>] The array of objects containing the repository information.
  # @param general [Boolean] Determines if the default CSV headings are to be used.
  # @param write [Boolean] The flag that determines if results are written to CSV.
  # @param filename [String] The name of the file to write CSV results. The default is `yahoo_git.csv`.
  # @return None
  # @note The results are displayed to standard output and written to the default CSV file `yahoo_git.csv`.
  def create_csv(headers = @csv_headers, data = @repos, general = true, write=true, filename = 'yahoo_git.csv')
    @csv = header_row(headers)
    data = data || @repos
    if general
      data.each_index do |i|
        data[i].each do |k|
          @csv+=create_csv_row([k['name'], k['html_url'],k['teams_url'],k['updated_at'],k['watchers_count'],k['forks_count'],k['open_issues_count'],k['language']])
        end
      end 
    else
      @csv += create_csv_row(data) 
    end 
    if write
      write_csv(filename)
    end  
  end
  private
  # @!method header_row(arr = [])
  # Formats the header row of a CSV file.
  # @param arr [Array] the array that contains header names that need to be converted into an appropriate header name that can
  # be used in a Liquid tag: <string>_<string>
  # @!visibility private
  # @return [String] Returns a CSV string with field values containing lower-case letters and no spaces .
  def header_row(arr = [])
      str = ""
      if not arr.empty?
        arr.each do |i|
          str += i.downcase.gsub(/[^a-zA-Z0-9 ]/, "").gsub(" ", "_") + ","
        end
      end
      str.chop + "\n"
  end
  # @!method create_csv_row(data)
  # Creates a CSV line.
  # @param data [Array, Hash, String] the row data that needs to be converted to CSV.
  # @!visibility private
  # @return [String] Returns a CSV string.
  def create_csv_row(data)
    if data.class == Array
      data.to_csv
    elsif data.class == Hash 
      data.values.to_csv
    elsif data.class == String 
      data.strip + "\n" 
    else
      data.to_s + "\n"
    end
  end
  # @!method write_csv(filename = 'yahoo_git.csv')
  # Writes the CSV stored in the instance variable `@csv` to file.
  # @param filename [String] the name of the file.  The default file name is `yahoo_git.csv`.
  # @!visibility private
  # @return None
  def write_csv(filename = 'yahoo_git.csv')
    open(filename, 'w') do |f|
      f.puts @csv
    end
    puts "Your data has been written to '" + filename + "'."
  end
  # @!method display_repos(team, repos)
  # Displays the repos of a team.
  # (see #display_members)
  # @param team [String] the GitHub team belonging to an org.
  # @param repos [Array[Hash{String}]] the array of objects containing repo information.
  # @!visibility private
  # @return [String] Returns a CSV string of the team repos.
  def display_repos(team, repos)
    repos.each do |a| 
        border = "#" * border_size(team)
        printf("%-80s", border + " " + team + " " + border + "\n\n")  
      if a.empty?
        printf("%-80s", "No repos for #{team}.")  
        print "\n\n"
        return create_csv_row("No repos for #{team}.")
      end
      a.each do |i|
        language = i["language"].nil? ? "" : i["language"].strip
        printf("%-25s %-30s\n", "#{@@headings[:repo_name]}: ",  i["name"].strip)
        printf("%-25s %-30s\n", "#{@@headings[:repo_url]}: ", i["html_url"])
        printf("%-25s %-30s\n", "#{@@headings[:repo_desc]}: ", i["description"])
        printf("%-25s %-30s\n", "#{@@headings[:git_url]}: ", i["git_url"])
        printf("%-25s %-30s\n", "#{@@headings[:watchers_count]}: ",  i["watchers_count"])
        printf("%-25s %-30s\n", "#{@@headings[:forks_count]}: ", i["forks_count"])
        printf("%-25s %-30s\n", "#{@@headings[:open_issues_count]}: ", i["open_issues_count"])
        printf("%-25s %-30s\n", "#{@@headings[:updated_at]}: ", i["updated_at"])
        printf("%-25s %-30s\n", "#{@@headings[:language]}: ", language)
        puts 
        return create_csv_row([i["name"], i["html_url"], i["description"], i["git_url"], i["watchers_count"], i["forks_count"], i["open_issues_count"], i["updated_at"], language])
      end
    end
  end
  # @!method display_members(team, members)
  # Displays the members of a team.
  # (see #display_repos)
  # @param team [String] the GitHub team belonging to an org.
  # @param members [Array[Hash{String}]] the array of objects containing team member information.
  # @!visibility private
  # @return [String] Returns a CSV string of the team member information.
  def display_members(team, members)
    csv = ""
    members.each do |a| 
        border = "#" * border_size(team)
        printf("%-80s", border + " " + team + " " + border + "\n\n")  
      if a.empty?
        printf("%-80s", "No members on this team.")  
        print "\n\n"
        return create_csv_row("No members on this team.")
      end
      a.each do |i|
        printf("%-25s %-30s\n", "#{@@headings[:login]}: ",  i["login"].strip)
        printf("%-25s %-30s\n", "#{@@headings[:html_url]}: ", i["html_url"])
        printf("%-25s %-30s\n", "#{@@headings[:organizations_url]}: ", i["organizations_url"])
        printf("%-25s %-30s\n", "#{@@headings[:repos_url]}: ", i["repos_url"])
        puts 
        return create_csv_row([i["login"], i["html_url"], i["organizations_url"], i["repos_url"]])
      end
    end
  end
  # @!method get_members(org, qs)
  # Fetches the members of an org and saves the response to the instance variable `@members`.
  # (see #get_teams and #get_repos)
  # @param org [String] a GitHub organization.
  # @param qs [String] the query string to append to the GitHub Members API resource URI.
  # @!visibility private
  # @return None
  def get_members(org, qs)
     uri = @@base_url + "orgs/" + org + "/members"
     @members = make_call(uri, qs)
  end
  # @!method get_teams(org, qs)
  # Fetches the teams for a GitHub organization and saves the response to the instance variable `@teams`.
  # (see #get_members and #get_repos)
  # @param org [String] a GitHub organization.
  # @param qs [String] the query string to append to the GitHub Members API resource URI.
  # @!visibility private
  # @return None
  def get_teams(org, qs)
     uri = @@base_url + "orgs/" + org + "/teams"
     @teams = make_call(uri, qs)
  end
  # @!method get_repos(org, qs)
  # Fetches the repositories for a GitHub organization and saves the response to the instance variable `@repos`.
  # (see #get_members and #get_team)
  # @param org [String] a GitHub organization.
  # @param qs [String] the query string to append to the GitHub Members API resource URI.
  # @!visibility private
  # @return None
  def get_repos(org, qs)
     uri = @@base_url + "orgs/" + org + "/repos"
     @repos = make_call(uri, qs)
  end
  # @!method display_short
  # Outputs the short-form version of the GitHub data: members, teams, repos
  # (see #display_medium and #display_long)
  # @!visibility private
  # @return None
  def display_short
    i = 0
    @data.each do |a|
       border = "#" * border_size(@@titles[i])
       printf("%-80s", border + " Yahoo #{@@titles[i]} " + border + "\n\n")        
       a.each do |j|
          j.each do |k|
            if @@titles[i] == "Members"
              printf("%-20s %-30s\n", "Login Name: ", k["login"])
              printf("%-20s %-30s\n", "URL: ", k["html_url"])
            elsif @@titles[i] == "Teams" 
              printf("%-20s %-30s\n", "Team Name: ", k["name"])
              printf("%-20s %-30s\n", "URL: ", k["url"])
            else
               printf("%-20s %-30s\n", "Repo: ", k["name"])
               printf("%-20s %-30s\n", "URL: ",  k["url"])  
            end 
            puts "-" * 80
            puts 
          end
       end
       i += 1
    end
  end
  # @!method display_medium
  # Outputs the medium-form version of the GitHub data: members, teams, repos
  # (see #display_short and #display_long)
  # @!visibility private
  # @return None
  def display_medium
    i = 0
    @data.each do |a|
       border = "#" * border_size(@@titles[i])
       printf("%-80s", border + " Yahoo #{@@titles[i]} " + border + "\n\n")        
       a.each do |j|
          j.each do |k|
            if @@titles[i] == "Members"
               printf("%-25s %-30s\n", "#{@@headings[:login]}: ", k["login"])
               printf("%-25s %-30s\n", "#{@@headings[:html_url]}: ", k["html_url"])
               printf("%-25s %-30s\n", "#{@@headings[:organizations_url]}: ", k["organizations_url"])
               printf("%-25s %-30s\n", "#{@@headings[:repos_url]}: ", k["repos_url"])
            elsif @@titles[i] == "Teams" 
               printf("%-20s %-30s\n", "#{@@headings[:team_name]}: ", k["name"])
               printf("%-20s %-30s\n", "#{@@headings[:description]}: ", k["description"])
               printf("%-20s %-30s\n", "#{@@headings[:members_url]}: ", k["members_url"])
               printf("%-20s %-30s\n", "#{@@headings[:repositories_url]}: ", k["repositories_url"])
            else
               language = k["language"].nil? ? "" : k["language"].strip
               printf("%-20s %-30s\n", "#{@@headings[:repo_name]}: ", k["name"])
               printf("%-20s %-30s\n", "#{@@headings[:repo_url]}: ", k["html_url"])  
               printf("%-20s %-30s\n", "#{@@headings[:teams_url]}: ", k["teams_url"])  
               printf("%-20s %-30s\n", "#{@@headings[:updated_at]}: ", k["updated_at"])  
               printf("%-20s %-30s\n", "#{@@headings[:stargazers_count]}: ", k["stargazers_count"])  
               printf("%-20s %-30s\n", "#{@@headings[:watchers_count]}: ", k["watchers_count"])  
               printf("%-20s %-30s\n", "#{@@headings[:forks_count]}: ", k["forks_count"])  
               printf("%-20s %-30s\n", "#{@@headings[:open_issues_count]}: ",k["open_issues_count"])  
               printf("%-20s %-30s\n", "#{@@headings[:language]}: ", language)
            end 
            puts "-" * 80
            puts 
          end
       end 
       i += 1
    end 
  end
  # @!method display_long
  # Outputs the long-form version of the GitHub data: members, teams, repos
  # (see #display_medium and #display_short)
  # @!visibility private
  # @return None
  def display_long
    i = 0
    @data.each do |a|
       border = "#" * border_size(@@titles[i])
       printf("%-80s", border + " Yahoo #{@@titles[i]} " + border + "\n\n")        
       a.each do |j|
          j.each do |k|
            k.each_pair do |k,v|
              next if k == "owner"
              printf("%-20s %-30s\n", k+":", v)
            end
            puts "-" * 80
            puts
          end
      end
      i += 1
      puts
    end 
  end
  # @!method make_call(uri, qs)
  # Makes the REST call to the GitHub API.
  # @param uri [String] the GitHub API resource URI.
  # @param qs [String] the query string to append to the GitHub Members API resource URI.
  # @note Also handles paging and errors.
  # @!visibility private
  # @return [Object] the response object
  def make_call(uri, qs)
    output = []
    link = nil
    response = nil
    if qs
       uri += "?per_page=100&" + URI.escape(qs)
    end
    begin  
      req_uri = URI(uri)
      req = Net::HTTP::Get.new(req_uri)
      Net::HTTP.start(req_uri.host, req_uri.port, :use_ssl => req_uri.scheme == 'https') do |http| 
        request = Net::HTTP::Get.new req_uri
        request.basic_auth @username, @password
        response = http.request request
        status_code = response.code
        if status_code !~ /2\d\d/
          if status_code =~ /4\d\d/
            puts "Authorization error. Check your credentials."
            exit 1
          elsif status_code =~ /3\d\d/
            puts "There has been a redirect issue."
            exit 2
          end
        end
      output.push(JSON.parse response.body)
      link = response.header["link"]
      end
      unless link.nil?
        link_info = /^<(https:\/\/api.github.com\/\w+\/\d+\/\w+\?.*?page=\d)>; rel="(\w+)"/.match(link).captures
        uri = link_info[0]
        next_uri = link_info[1]
      end
    end while next_uri == "next"
    return output 
  end 
  # @!method border_size(title)
  # Calculates how many border characters must be used on both sides of the `title`.
  # @param title [String] the title of the section to be displayed, such as "Members", "Teams", "Repos".
  # @!visibility private
  # @return [Integer] the number of border characters to be printed on both sides of the `title`.
  def border_size(title)
    full_title = " " + title + " "
    bd_size = (80-full_title.length)/2
  end
end
