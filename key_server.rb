require 'sinatra'
require 'securerandom'
require 'rufus-scheduler'

class KeyServer
  attr_reader :generated_keys
  attr_reader :blocked_keys
  attr_reader :purged_keys
  attr_reader :time_to_live
  attr_reader :time_to_block

  def initialize(ttl=nil, ttb=nil)
    @generated_keys = Hash.new
    @blocked_keys = Hash.new
    @purged_keys = Array.new
    @all_keys = Hash.new
    @time_to_live = ttl || 300
    @time_to_block = ttb || 60
  end

  def create_new_key
    key = SecureRandom.urlsafe_base64
    @purged_keys.include?(key) ? create_new_key  : key
  end

  def generate_key
    key = create_new_key
    #add new key to hashes that maintain records
    @generated_keys.merge!({key => Time.now})
    @all_keys.merge!(@generated_keys) { |key, v1, v2| v1 }
    key
  end

  def get_available_key
    if(@generated_keys.empty?)
      return "404. No keys available"
    else
      new_key = @generated_keys.keys.sample(1)
      @generated_keys.delete(new_key[0])
      @blocked_keys.merge!({new_key[0] => Time.now})
      return "#{new_key[0]}"
    end
  end

  def unblock_key(key)
    if (@blocked_keys.has_key?(key))
      curr_time = Time.now

      if (curr_time - @blocked_keys[key] > @time_to_live)
        @blocked_keys.delete(key)
        @purged_keys.push(key)
        return "Key deleted due to expiry"

      elsif (curr_time - @blocked_keys[key] > @time_to_block)
        @blocked_keys.delete(key)
        @generated_keys.merge!({key => (@all_keys[key] + @time_to_block)})
        return "The key has been unblocked. Request for new key."

      else
        @blocked_keys.delete(key)
        @generated_keys.merge!({key => Time.now})
        return "Request complete. Key has been unblocked"
      end

    elsif (@purged_keys.include?(key))
      return "Key has been deleted"

    elsif @generated_keys.has_key?(key)
      return "Key is not available for unblocking. Already unblocked"
      
    else
      return "Invalid Key #{key}"
    end

  end

  def keep_key_alive(key)
    curr_time = Time.now()

    if(purged_keys.include?(key))
      return "The key has been deleted"

    elsif (!@all_keys.has_key?(key))
      return "Invalid Key"

    elsif(curr_time - @all_keys[key] > @time_to_live)     
      @generated_keys.delete(key)
      @blocked_keys.delete(key)
      return "The key has been deleted due to inactivity."

    else
      @all_keys.merge!({key => Time.now})
      if(@generated_keys.has_key?(key))
        @generated_keys.merge!({key => Time.now})
      end
      return "Time to live extended for #{key}"
    end

  end

  def delete_key(key)
    if (!@all_keys.has_key?(key))
      return "Invalid Key"
    elsif @blocked_keys.has_key?(key)
      @blocked_keys.delete(key)
    elsif @generated_keys.has_key?(key)
      @generated_keys.delete(key)
    end
    @purged_keys << key
    "#{key} deleted"
  end

  def delete_unused_key
    if(!@blocked_keys.empty?)
      @blocked_keys.each do |key, time|
        curr_time = Time.now
        if(curr_time - time > @time_to_live)
          puts "#{key} has been deleted automatically"
          @blocked_keys.delete(key)
          @purged_keys << key
        end
      end
    end

    if(!@generated_keys.empty?)
      @generated_keys.each do |key, time|
        curr_time = Time.now
        if(curr_time - time > @time_to_live)
          puts "#{key} has been deleted automatically"
          @generated_keys.delete(key)
          @purged_keys << key
        end
      end
    end
  end

  def unblock_blocked_key
    if(!@blocked_keys.empty?)
      @blocked_keys.each do |key, time|
        curr_time = Time.now
        if(curr_time - time > @time_to_block)
          @blocked_keys.delete(key)
          @generated_keys.merge!(key => @all_keys[key])
        end
      end
    end
  end
end


=begin
if __FILE__ == $0
  k1 = KeyServer.new
  scheduled_delete = Rufus::Scheduler.new
  scheduled_unblock = Rufus::Scheduler.new

  scheduled_delete.every '1m' do
    k1.delete_unused_key
  end

  scheduled_unblock.every '10s' do
    k1.unblock_blocked_key
  end

  k1.driver
end
=end