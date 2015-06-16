require 'sinatra'
require './database.rb'
require 'rufus-scheduler'

key_records = Database.new(30,10)

scheduled_cleanup = Rufus::Scheduler.new
scheduled_cleanup.every '1s' do
	key_records.clean_db
end


get '/' do
  "Landing Page"
end
get '/generate' do
  key_records.create_new_key
end

get '/get' do 
  key_records.get_key
end

get '/unblock/?:key' do
  key_records.unblock(params['key'])
end

get '/keep_alive/?:key' do
  key_records.keep_alive(params['key'])
end

get '/delete/?:key' do
  api.delete_key(params['key'])
end
