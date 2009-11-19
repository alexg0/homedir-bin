#! /usr/bin/ruby

require 'getoptlong'
require 'resolv'

$TLD_CHECK_ARRAY = []
$VERBOSE         = false


def parse_arguments ()
  parser = GetoptLong.new;
  
  parser.set_options(['--tls',    '-t', GetoptLong::OPTIONAL_ARGUMENT],
		     ['--verbose','-v', GetoptLong::NO_ARGUMENT]);
  
  parser.each_option { |name, arg|
    case name.sub(/^--/, '')
    when 'tls'
      $TLD_CHECK_ARRAY << arg
    when 'verbose'
      $VERBOSE = true
    else
      raise "unhandled arg: --#{name} #{arg}"
    end
  }
end

$dns = Resolv::DNS.new
def begin_process_name (name)
  begin
    res = $dns.getresource(name, Resolv::DNS::Resource::IN::NS)
    print "taken: #{name}\n" if $VERBOSE
  rescue Resolv::ResolvError
    print "available: #{name}\n"
  end
end

parse_arguments()

$stdin.each { |line|
  line.chomp!
  if !$TLD_CHECK_ARRAY.empty? then
    $TLD_CHECK_ARRAY.each { |tld| 
      begin_process_name("#{line}.#{tld}");
    }
  else
    begin_process_name(line)
  end
}

		   
