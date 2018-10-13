require 'open-uri'
require 'json'
require 'io/console'

# Set up initial values
def set_api_endpoint
  # Page size isolated to set by an optional argument if needed
  number_of_stations = 13
  api_endpoint_base = 'http://api.lamusica.com/audio/content/stations?page_size='
  return api_endpoint_base + number_of_stations.to_s
end

# Collect callsign and streamURL of each station
def set_stations(url)
  response = JSON.load(open(url))
  streamURLs = {}
  response["data"].each do |station|
    streamURLs[station["callSign"]] = station["streamURL"]
  end
  return streamURLs
end

# Pick a streaming server for each station
def set_servers(stations)
  streams = {}
  stations.each do |cs, url|
    station_streams = open(url).read.split
    # Pick a random stream from those available
    stream = station_streams[rand(station_streams.length)]
    streams[cs] = stream
  end
  return streams
end

# Download the streams in separate processes
def download(streams)
  pids = []
  streams.each do |cs, stream|
    pids << Process.detach(fork {
      exec "wget", "--quiet", stream, "-O", "#{cs}.mp3"
    }).pid
  end
  puts "Downloads started."
  puts "Press any key to end script and halt all downloads."
  # Wait for user's cue to end the downloads (could be extended for pausing, etc.)
  STDIN.getch

  pids.each { |pid| Process.kill('KILL', pid) }
end

# Give immediate feedback to let user know the program is executing
puts "Please wait while your downloads start..."
# Method calls for main script begin here
api_endpoint = set_api_endpoint
stations = set_stations(api_endpoint)
streams = set_servers(stations)
download(streams)
