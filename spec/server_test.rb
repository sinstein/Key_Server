require "spec_helper"
require_relative '../database.rb'
require 'rufus-scheduler'

RSpec.configure do |c|
  c.color = true
end


describe "Key Server", :keyserver => true do

  it "- throws 404 when keys are requested but not generated" do
    get "/get"
    expect(last_response.body).to eq("404 NO KEY AVAILABLE")
  end

  it "- can generate keys on request" do
    get "/generate"
    key = last_response.body
    expect(last_response.body.size).to eq(22)
  end

  it "- can get and block generated keys on request" do
    get "/get"
    key = last_response.body
    expect(last_response.body.size).to eq(22)

  end
  
end
