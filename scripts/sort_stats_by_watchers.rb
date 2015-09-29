require 'csv'

=begin
This sorts the CSV file for Yahoo's
public Git stats by the number of watchers
and writes the results to `data/sorted_public_yahoo_git.csv`.
=end

my_csv = CSV.read '_data/public_yahoo_git.csv'
header_row = my_csv.shift
header_row = header_row.to_csv
csv = header_row
my_csv.sort! { |b, a| a[4].to_i <=> b[4].to_i }
my_csv.uniq!(&:first)

my_csv.each do |l| 
  csv += l.to_csv
end
open("_data/sorted_public_yahoo_git.csv", "w") do |f|
  f.write(csv)
end
