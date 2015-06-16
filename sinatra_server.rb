require 'sinatra'
require './database.rb'
require 'rufus-scheduler'

key_records = Database.new(30,10, ':memory:')

#scheduled_cleanup = Rufus::Scheduler.new
#scheduled_cleanup.every '1s' do
#	key_records.clean_db
#end


get '/' do
  "Landing Page"
end
get '/generate' do
  key_records.generate_key
end

get '/get' do 
  key_records.get_available_key
end

get '/unblock/?:key' do
  key_records.unblock(params['key'])
end

get '/keep_alive/?:key' do
  key_records.keep_key_alive(params['key'])
end

get '/delete/?:key' do
  key_records.delete_key(params['key'])
end
