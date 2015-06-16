require 'rack/test'
require 'rspec'
require 'server_test.rb'
require 'api_test.rb'

require_relative "../database.rb"
require_relative '../sinatra_server.rb'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure { |c| c.include RSpecMixin }
