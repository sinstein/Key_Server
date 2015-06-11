require 'sinatra'
require './key_server.rb'

api = KeyServer.new(30,10)

scheduled_delete = Rufus::Scheduler.new
scheduled_unblock = Rufus::Scheduler.new

scheduled_delete.every '10s' do
  api.delete_unused_key
end

scheduled_unblock.every '3s' do
  api.unblock_blocked_key
end


get '/' do
  "Landing Page"
end
get '/generate' do
  api.generate_key
end

get '/get_key' do 
  api.get_available_key
end

get '/unblock_key/?:key' do
  api.unblock_key(params['key'])
end

get '/delete_key/?:key' do
  api.delete_key(params['key'])
end

get '/keep_alive/?:key' do
  api.keep_key_alive(params['key'])
end
