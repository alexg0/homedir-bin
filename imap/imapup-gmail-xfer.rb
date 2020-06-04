#!/usr/bin/env ruby
require 'net/imap'

# TODO: fix this 
AG_PASS='motofoto'

# Source server connection info.
SOURCE_HOST = 'imap.gmail.com'
SOURCE_PORT = 993
SOURCE_SSL  = true
SOURCE_USER = 'alexg@iolga.com'
SOURCE_PASS = AG_PASS

# Destination server connection info.
DEST_HOST = 'imap.gmail.com'
DEST_PORT = 993
DEST_SSL  = true
DEST_USER = 'alexg@alexland.us'
DEST_PASS = AG_PASS

# Mapping of source folders to destination folders. The key is the name of the
# folder on the source server, the value is the name on the destination server.
# Any folder not specified here will be ignored. If a destination folder does
# not exist, it will be created.
FOLDERS = {
#  'INBOX' => 'INBOX',
  'unlabeled_inbox' => 'INBOX',
  'unlabeled_archived' => nil,
  'in/p4' => nil,
  'in/cnu' => nil,
  'in/cnu_batch' => nil, # ignore batch2
  'in/nagios' => nil,
  'in/c.fin'  => nil,
  'in/c.misc' => nil,
  'in/c.news' => nil,
  'in/c.serv' => nil,
  'in/c.shop' => nil,
  'in/c.travel' => nil,
  'in/z.bounces' => nil,
  'ml/essential-skills' => nil,
  'ml/mindlist' => nil,
  'ml/nlptalk' => nil,
  'ml/rails' => nil,
  'ml/sfba_hypnosis' => nil,
  'ml/ss' => nil,
  's/fin' => nil,
  's/mortgage' => nil,
  's/software' => nil,
  's/travel' => nil,
  '[Gmail]/Drafts' => nil,
  '[Gmail]/Sent Mail' => nil,
#  '[Gmail]/Spam' => nil,
  '[Gmail]/Spam' => 'xx_report_as_spam',
  
  # deal with Starred
  
  

#  'sourcefolder' => 'gmailfolder'
}

$folder_filter = ARGV.first

# Utility methods.
def dd(message)
   puts "[#{DEST_USER}@#{DEST_HOST}] #{message}"
end

def ds(message)
   puts "[#{SOURCE_USER}@#{SOURCE_HOST}] #{message}"
end

def copy_folder_messages(source, source_folder, dest, dest_folder)
  dest_folder = source_folder unless dest_folder

  # Open source folder in read-only mode.
  begin
    ds "selecting folder '#{source_folder}'..."
    source.examine(source_folder)
  rescue => e
    ds "error: select failed: #{e}"
    next
  end
  
  # Open (or create) destination folder in read-write mode.
  begin
    dd "selecting folder '#{dest_folder}'..."
    dest.select(dest_folder)
  rescue => e
    begin
      dd "folder not found; creating..."
      dest.create(dest_folder)
      dest.select(dest_folder)
    rescue => ee
      dd "error: could not create folder: #{e}"
      next
    end
  end
  
  # Build a lookup hash of all message ids present in the destination folder.
  dest_info = {}
  
  dd 'analyzing existing messages...'
  uids = dest.uid_search(['ALL'])
  if uids && !uids.empty? then
    dest.uid_fetch(uids, ['ENVELOPE']).each do |data|
      dest_info[data.attr['ENVELOPE'].message_id] = true
    end
  end
  
  # Loop through all messages in the source folder.
  source_uids = source.uid_fetch(source.uid_search(['ALL']), ['ENVELOPE'])
  source_count = source_uids.size
  source_uids.each_with_index do |data, msg_num|
    mid = data.attr['ENVELOPE'].message_id

    if !mid then
      # dd "skipping [#{msg_num}/#{source_count}] mid=#{mid}"
      next
    end

    # If this message is already in the destination folder, skip it.
    next if dest_info[mid]
    
    # Download the full message body from the source folder.
    ds "downloading message (#{source_folder}) #{mid}..."
    msg = source.uid_fetch(data.attr['UID'], ['RFC822', 'FLAGS',
        'INTERNALDATE']).first
    
    # Append the message to the destination folder, preserving flags and
    # internal timestamp.
    dd "storing message (#{dest_folder} [#{msg_num}/#{source_count}]) #{mid}..."
    dest.append(dest_folder, msg.attr['RFC822'], msg.attr['FLAGS'],
        msg.attr['INTERNALDATE'])
  end
  
ensure
  source.close
  dest.close
end

# Connect and log into both servers.
ds 'connecting...'
source = Net::IMAP.new(SOURCE_HOST, SOURCE_PORT, SOURCE_SSL)

ds 'logging in...'
source.login(SOURCE_USER, SOURCE_PASS)

dd 'connecting...'
dest = Net::IMAP.new(DEST_HOST, DEST_PORT, DEST_SSL)

dd 'logging in...'
dest.login(DEST_USER, DEST_PASS)

# Loop through folders and copy messages.
FOLDERS.each do |source_folder, dest_folder|
  next if $folder_filter && source_folder !~ /#{$folder_filter}/
  copy_folder_messages(source, source_folder, dest, dest_folder) 
end

puts 'done'
