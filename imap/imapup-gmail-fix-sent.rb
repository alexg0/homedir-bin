#!/usr/bin/env ruby
require 'net/imap'
require 'thread'

QUEUE_SIZE=10000

# TODO: fix this 
AG_PASS='motofoto'

# Source server connection info.
GMAIL_HOST = 'imap.gmail.com'
GMAIL_PORT = 993
GMAIL_SSL  = true
GMAIL_USER = 'alexg@alexland.us'
GMAIL_PASS = AG_PASS

FROM_ADDRESSES = %w( alexg@cashnetusa.com 
                     alexg@technologist.com
                     alexg@alexland.org )

$folder_filter = ARGV.first

# Utility methods.
def dd(message)
   puts "[#{GMAIL_USER}@#{GMAIL_HOST}] #{message}"
end

def move_some_mail(imap, source_folder, dest_folder, search_keys)
  dest_folder = source_folder unless dest_folder

  # Open source folder in read-write mode.
  begin
    dd "selecting folder '#{source_folder}'..."
    imap.select(source_folder)
  rescue => e
    dd "error: select failed: #{e}"
    return
  end

  dd 'analyzing existing messages...'
  message_ids = imap.search(search_keys)
  puts "message_ids = %s" % message_ids.join(",")
#  message_ids = message_ids.first(5)

  if message_ids && !message_ids.empty? then
    message_ids.each do |message_id|
      puts "message_id = %s" % message_id
#      msg = imap.fetch(message_id, ['RFC822', 'FLAGS'])
#      puts "msg = %s" % msg
      imap.copy(message_id, dest_folder)
      imap.store(message_id, "+FLAGS", [:Deleted])

    end
  end
  
ensure
  imap.close
end

# Connect and log into both servers.
dd 'connecting...'
imap = Net::IMAP.new(GMAIL_HOST, GMAIL_PORT, GMAIL_SSL)

dd 'logging in...'
imap.login(GMAIL_USER, GMAIL_PASS)

# Loop through folders and copy messages.
move_some_mail(imap, '[Gmail]/All Mail', '[Gmail]/Sent Mail', 
               ['FROM', 'alexg@area.com' ]
               )

move_some_mail(imap, '[Gmail]/All Mail', '[Gmail]/Sent Mail', 
               ['FROM', 'alexg@technologist.com' ]
               )

puts 'done'
