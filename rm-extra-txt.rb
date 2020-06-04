#! /usr/bin/ruby -w

require 'find'
require 'ftools'

start_dir = ARGV[0] or die "no argument given"

txt_files = []

Find.find( start_dir ) { |f|
  if (FileTest.file?(f) && /.TXT$/.match(f)) then
    b = f.sub(/.TXT$/,"")
    txt_files.push(f) if (!FileTest::file?(b + ".jpg") \
			  && !FileTest::file?(b + ".JPG") \
			  && !FileTest::file?(b + ".CRW") \
			  && !FileTest::file?(b + ".crw") \
			  );
  end
}

txt_files.each { |f| 
  print "#{f}\n"
}
  
