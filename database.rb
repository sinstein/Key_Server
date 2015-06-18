require 'sqlite3'
require 'securerandom'

class Database
  attr_reader :time_to_block
  attr_reader :time_to_live

  def initialize (ttl = 300, ttb = 60, fileName = 'keys.db')
    @time_to_live = ttl
    @time_to_block = ttb
    @db = SQLite3::Database.new fileName
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS "keys" (
        key varchar(20),
        keep_alive_last int,
        block_last int );
    SQL
  end

  def generate_key
    key = SecureRandom.urlsafe_base64
    while (key_exists?(key))
      key = SecureRandom.urlsafe_base64
    end
    @db.execute("INSERT INTO keys VALUES (?, ?, ?)",
     key, Time.now.to_i, 0)
    key
  end

  def get_available_key
    rows = @db.execute("SELECT * FROM keys WHERE block_last = ?", 0)
    if(rows.size == 0)
      return false
    end
    key = rows[0][0]
    @db.execute("UPDATE keys SET block_last = ? WHERE key = ?",
     Time.now.to_i, key)
    key
  end

  def unblock(key)
    if(key_exists?(key))
      curr_time = Time.now.to_i
      @db.execute("UPDATE keys SET block_last = ?  WHERE key = ?", 0, key)
      true
    end
    false
  end

  def keep_key_alive(key)
    if(key_exists?(key))
      curr_time = Time.now.to_i
      @db.execute("UPDATE keys SET keep_alive_last = ?  WHERE key = ?",
       curr_time, key)
      true
    end
    false
  end

  def delete_key(key)
    if(key_exists?(key))
      @db.execute("DELETE FROM keys WHERE key = ?", key)
      true
    end
    false
  end

  def count_alive_keys
    return @db.execute("SELECT * FROM keys").size()
  end

  def count_blocked_keys
    return @db.execute("SELECT * FROM keys WHERE block_last <> ?", 0).size()
  end

  def key_exists?(key) 
    data = @db.execute("SELECT * FROM keys WHERE key = ?", key)
    if (data.size == 0)
      return false
    end
    true
  end

  def clean_db
    curr_time = Time.now.to_i
    @db.execute("DELETE FROM keys WHERE ? - keep_alive_last > ?",
     curr_time, @time_to_live)
    @db.execute("UPDATE keys SET block_last = ? WHERE ? - block_last > ?",
     0, curr_time, @time_to_block)
  end
end


