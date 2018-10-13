require 'open-uri'
require 'json'
require 'fileutils'

# Page size as a separate constant so that if more stations are added it will be obvious that this is a limiting factor on the results
NUMBER_OF_STATIONS = 3
# API endpoint as a constant in case a developer needs to change it later
API_ENDPOINT = 'http://api.lamusica.com/audio/content/stations?page_size='

@url = API_ENDPOINT + NUMBER_OF_STATIONS.to_s

@response = JSON.load(open(@url))

# Collect callsign and streamURL of each station
@streamURLs = {}
@response["data"].each do |station|
  @streamURLs[station["callSign"]] = station["streamURL"]
end

# Pick a streaming server for each station
@streams = {}
@streamURLs.each do |cs, url|
  station_streams = open(url).read.split
  stream = station_streams[rand(station_streams.length)]
  @streams[cs] = stream
end

# Download the streams in separate processes
@pids = []
@streams.each do |cs, stream|
  @pids << Process.detach(fork {
    exec "wget", "--quiet", stream, "-O", "#{cs}.mp3"
  }).pid
end

# Allows for other commands to be added later:
comm = ""
while comm.downcase != "exit"
  puts "Type 'EXIT' to terminate downloads."
  comm = gets.chomp
end

@pids.each { |pid| Process.kill('KILL', pid) }
puts "Done"
