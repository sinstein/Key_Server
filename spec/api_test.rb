require_relative '../key_server.rb'

RSpec.configure do |c|
	c.color = true
end

RSpec.describe "Data handling of Key Server" do 
	before(:each) do
		@api = KeyServer.new
		10.times { @api.generate_key }
		5.times { @api.get_available_key }
			
	end
	
	context "With no key deleted automatically" do
		it "- generates a new key when requested" do
			api = KeyServer.new
			10.times { api.generate_key }
			expect(api.generated_keys.length).to eq 10
		end

		it "- allots (or blocks) a key from list when requested" do
			expect(@api.blocked_keys.length).to eq 5
		end

		it "- unblocks a key when requested" do
			expect(@api.blocked_keys.length).to eq 5
			expect(@api.generated_keys.length).to eq 5
			#Unblocking one key
			sample_key = @api.blocked_keys.to_a.sample(1)
			@api.unblock_key(sample_key[0][0])
			#unblocking one key should reduce it from blocked list and add it to generated list
			expect(@api.blocked_keys.length).to eq 4
			expect(@api.generated_keys.length).to eq 6 
		end
	end

	context "Deletes key when requested" do
		
		it "- deletes unblocked key" do
			expect(@api.generated_keys.length).to eq 5
			sample_key = @api.generated_keys.to_a.sample(1)
			@api.delete_key(sample_key[0][0]) 
			expect(@api.generated_keys.length).to eq 4
		end

		it "- deletes blocked key" do
			expect(@api.blocked_keys.length).to eq 5
			sample_key = @api.blocked_keys.to_a.sample(1)
			@api.delete_key(sample_key[0][0]) 
			expect(@api.blocked_keys.length).to eq 4
		end
	end

	context "Sets time limits" do
		it "- auto set times" do
			expect(@api.time_to_live).to eq 300
			expect(@api.time_to_block).to eq 60
		end

		it "- time set by user" do
			api = KeyServer.new(100, 10)
			expect(api.time_to_live).to eq 100
			expect(api.time_to_block).to eq 10
		end
	end

	context "Checks time-out for keys" do
		it "- makes key unavailable for unblocking after time to block expires" do
			api = KeyServer.new(1,2)
			10.times { api.generate_key }
			5.times { api.get_available_key }
			sleep(3)
			sample_key = api.blocked_keys.to_a.sample(1)
			api.keep_key_alive(sample_key[0][0]) 
			expect(api.blocked_keys.length).to eq 4
			expect(api.generated_keys.length).to eq 5
		end

		it "- makes key unavailable for unblocking after time to live expires" do
			api = KeyServer.new(2,2)
			10.times { api.generate_key }
			5.times { api.get_available_key }
			sleep(3)
			sample_key = api.blocked_keys.to_a.sample(1)
			api.unblock_key(sample_key[0][0]) 
			expect(api.blocked_keys.length).to eq 4
			expect(api.generated_keys.length).to eq 5
		end

		it "- makes key unavailable for keep-alive after time to live expires" do
			api = KeyServer.new(2,2)
			10.times { api.generate_key }
			5.times { api.get_available_key }
			sleep(3)
			sample_key = api.generated_keys.to_a.sample(1)
			api.keep_key_alive(sample_key[0][0]) 
			expect(api.blocked_keys.length).to eq 5
			expect(api.generated_keys.length).to eq 4
		end
	end

	context "Auto cleans keys" do
		it "- auto unblocks keys after time to block" do
			api = KeyServer.new(2,2)
			10.times { api.generate_key }
			5.times { api.get_available_key }
			scheduled_unblock = Rufus::Scheduler.new
			scheduled_unblock.every '2s' do
				api.unblock_blocked_key
			end
			sleep(4)
			expect(api.blocked_keys.length).to eq 0
  		end

  		it "- auto deletes unblocked keys after time to live" do
  			api = KeyServer.new(2,2)
			10.times { api.generate_key }
			5.times { api.get_available_key }
			scheduled_delete = Rufus::Scheduler.new
			scheduled_delete.every '2s' do
				api.delete_unused_key
			end
			sleep(4)
			expect(api.generated_keys.length).to eq 0
  		end

  		it "- auto deletes blocked keys after time to live" do
  			api = KeyServer.new(2,2)
			10.times { api.generate_key }
			5.times { api.get_available_key }
			scheduled_delete = Rufus::Scheduler.new
			scheduled_delete.every '2s' do
				api.delete_unused_key
			end
			sleep(4)
			expect(api.blocked_keys.length).to eq 0
  		end
	end
end
