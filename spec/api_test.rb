require_relative '../database.rb'
require 'rufus-scheduler'

RSpec.configure do |c|
	c.color = true
end

RSpec.describe "Data handling of Key Server" do 
	before(:each) do
		@key_records = Database.new(300, 60, ':memory:')
		10.times { @key_records.generate_key }
		5.times { @key_records.get_available_key }	
	end
	
	context "With no key deleted automatically" do
		it "- generates a new key when requested" do
			expect(@key_records.count_alive_keys).to eq 10
		end

		it "- allots (or blocks) a key from list when requested" do
			expect(@key_records.count_blocked_keys).to eq 5
		end

		it "- unblocks a key when requested" do
			expect(@key_records.count_blocked_keys).to eq 5
			expect(@key_records.count_alive_keys).to eq 10
			#Blocking one key
			sample_key = @key_records.get_available_key
			@key_records.unblock(sample_key)
			#Unblocking one key should reduce it from blocked list and add it to generated list
			expect(@key_records.count_blocked_keys).to eq 6
			expect(@key_records.count_alive_keys).to eq 10
		end
	end

	context "Deletes key when requested" do
		
		it "- deletes unblocked key" do
			expect(@key_records.count_alive_keys).to eq 10
			sample_key = @key_records.get_available_key
			@key_records.unblock(sample_key)
			@key_records.delete_key(sample_key) 
			expect(@key_records.count_alive_keys).to eq 10
		end

		it "- deletes blocked key" do
			expect(@key_records.count_blocked_keys).to eq 5
			sample_key = @key_records.get_available_key
			@key_records.delete_key(sample_key) 
			expect(@key_records.count_blocked_keys).to eq 6
		end
	end

	context "Sets time limits" do
		it "- auto set times" do
			expect(@key_records.time_to_live).to eq 300
			expect(@key_records.time_to_block).to eq 60
		end

		it "- time set by user" do
			key_records = Database.new(100, 10)
			expect(key_records.time_to_live).to eq 100
			expect(key_records.time_to_block).to eq 10
		end
	end

	context "Auto cleans keys" do
		it "- auto unblocks keys after time to block" do
			key_records = Database.new(2, 2, ':memory:')
			10.times { key_records.generate_key }
			5.times { key_records.get_available_key }
			scheduled_unblock = Rufus::Scheduler.new
			scheduled_unblock.every '1s' do
				key_records.clean_db
			end
			sleep(4)
			expect(key_records.count_blocked_keys).to eq 0
  		end

		it "- auto deletes unblocked keys after time to live" do
			key_records = Database.new(2, 2, ':memory:')
			10.times { key_records.generate_key }
			5.times { key_records.get_available_key }
			scheduled_delete = Rufus::Scheduler.new
			scheduled_delete.every '1s' do
				key_records.clean_db
			end
			sleep(4)
			expect(key_records.count_alive_keys).to eq 0
		end

		it "- auto deletes blocked keys after time to live" do
  			key_records = Database.new(2, 2, ':memory:')
			10.times { key_records.generate_key }
			5.times { key_records.get_available_key }
			scheduled_delete = Rufus::Scheduler.new
			scheduled_delete.every '1s' do
				key_records.clean_db
      		end
			sleep(4)
			expect(key_records.count_blocked_keys).to eq 0
		end
	end
end
