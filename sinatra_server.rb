require 'sinatra'
require './database.rb'
require 'rufus-scheduler'

key_records = Database.new(30,10, ':memory:')

if __FILE__ == $0
  scheduled_cleanup = Rufus::Scheduler.new
  scheduled_cleanup.every '1s' do
    key_records.clean_db
  end
end


get '/' do
  "Landing Page"
end

get '/generate' do
  key_records.generate_key
  return [200, "KEY GENERATED"]
end

get '/get' do 
  key =  key_records.get_available_key
  if(!key)
    return [404, "NO KEY AVAILABLE"]
  else
    return [200, key]
  end
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
