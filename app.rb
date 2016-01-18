#!/usr/bin/env ruby

$LOAD_PATH.unshift('helpers')
$LOAD_PATH.unshift('lib')

require 'rubygems'

require 'yaml'
require 'cfoundry'
require 'stats_helpers'
require 'apps_helpers'
require 'cloud_foundry_manager'
require 'scale_event'

require 'sinatra'
require 'sinatra/bootstrap'

include StatsHelpers
include AppsHelpers

config = CloudFoundryManager.config

puts "Cloudfoundry target: #{config.api}"
puts "Authenticating with user: #{config.username}"

app = CloudFoundryManager.application

puts "Application fetched: #{app.name} (#{app.routes.first.name})"
puts

threshold = 70
puts "CPU threshold: #{threshold}%"
puts "-"*30
puts

$events = []
$test_start = Time.now.to_i

Thread.new do
  while true do
    avg_cpu_load = app_average_cpu_load app
    avg_mem = app_average_memory app
  
    puts "App #{app.name} stats:"
    puts "-- Instances: #{app.total_instances}"
    puts "-- AVG CPU load: #{humanise_cpu_usage avg_cpu_load}"
    puts "-- AVG Memory: #{humanise_bytes_to_megabytes avg_mem}"
    puts
    if avg_cpu_load >= threshold
      puts "------------> AVG CPU Load went over threshold (#{threshold} %), scaling app by 1 instance"
      scale_app(app, 1)
      $events << ScaleEvent.new(app, :add_instance)
    end
  
    sleep 2.0
  end
end

register Sinatra::Bootstrap::Assets

get '/' do
  erb :events, :locals => {:events => $events}
end

get '/csv' do
  $events.map { |e| [e.timestamp - $test_start, e.instances_count].join(',') }.unshift("0,1").join("\n")
end

put '/start-test' do
  $test_start = Time.now.to_i
  $test_start.to_s
end


