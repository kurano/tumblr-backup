# -*- coding: utf-8 -*-

require 'tumblife'
require 'mongo'
require 'json'
 
config = YAML.load(File.read('config.yaml'))

Tumblife.configure do |c|
  c.consumer_key = config['tumblr']['consumer_key']
  c.consumer_secret = config['tumblr']['consumer_secret']
  c.oauth_token = config['tumblr']['oauth_token']
  c.oauth_token_secret = config['tumblr']['oauth_token_secret']
end
 
client = Tumblife.client
info = client.info(config['tumblr']['site'])
n = info.blog.posts

if ARGV[0]
  raise "#{ARGV[0]} is not a directory." unless File.stat(ARGV[0]).directory?
  backup_dir = File.open(ARGV[0])
  puts "Backup to #{ARGV[0]}."
  n = ARGV[1].to_i if ARGV[1]
else
  db = Mongo::Connection.new(config['mongo']['host'], config['mongo']['port']).db(config['mongo']['db'])
  db.authenticate(config['mongo']['user'], config['mongo']['pass'])
  begin
    coll = db.collection(config['mongo']['coll']) 
  rescue
    coll = db.create_collection(config['mongo']['coll'])
  end
end

puts "Start Backup #{n} Posts."

catch(:exit) do
 
  0.step(n, 20) do |o|
    posts = client.posts('kurano.tumblr.com', :reblog_info=>true, :offset=>o).posts
    posts.sort{|a, b| b.id <=> a.id}.each do |p|
      j = p.to_json
  
      # Backup to FileSystem
      if backup_dir
        open(File.join(backup_dir, "#{p.id}.json"), "w") do |f|
          f << j
        end
        next
      end
      
      # Backup to MongoDB
      doc = coll.find_one(:id => p.id)
      if doc
        puts "#{p.id} is stored"
        throw :exit # posts sorted by id descending 
      else
        coll.insert(JSON.parse(j))
      end
      
    end
    puts "Offset: #{o}"
    sleep 1.1
    
  end

end

puts "End Backup."
