require "spec_helper"

describe "Key Server", :keyserver => true do

  it "- throws 404 when keys are requested but not generated" do
    get "/get_key"
    expect(last_response.body).to eq("404. No keys available")
  end

  it "- can generate keys on request" do
    get "/generate"
  end

  it "- can get and block generated keys on request" do
    get "/get_key"
    key = last_response.body
  end

  it "- can unblock a blocked key on request" do
    get "/generate"
    get "/get_key"
    key = last_response.body
    get "/unblock_key/#{key}"
    expect(last_response.body).to eq("Request complete. Key has been unblocked")
  end

  it "- will not unblock an unblocked key" do
    get "/generate"
    get "/get_key"
    key = last_response.body
    get "/unblock_key/#{key}"
    get "/unblock_key/#{key}"
    expect(last_response.body).to eq("Key is not available for unblocking. Already unblocked")
  end

  it "- can delete an existing key on request" do
    get "/generate"
    get "/get_key"
    key = last_response.body
    get "/delete_key/#{key}"
    expect(last_response.body).to eq("#{key} deleted")
  end

  it "- will not delete aninvalid (non-existent) key" do
    get "/delete_key/sbcd"
    expect(last_response.body).to eq("Invalid Key")
  end

  it "- can keep key alive on request" do
    get "/generate"
    get "/get_key"
    key = last_response.body
    get "/keep_alive/#{key}"
    expect(last_response.body).to eq("Time to live extended for #{key}")
  end
end
