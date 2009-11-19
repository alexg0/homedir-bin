#! /bin/bash

LOGFILE=~/mail/log/index-mail.log
if [ -f $LOGFILE ]; then
  mv $LOGFILE $LOGFILE.1
fi

date > $LOGFILE
# run indexes
nice -n 10 ~/bin.shared/index-mail \
 -m ~/mail -o ~/mail.index \
 -s spool -s favorites -s sent -s archive -s unread \
 -c ~/fulltext/conf/mknmzrc.mail -t namazu \
 -x zappy -x mindlist -x nlptalk -x junk -x craigslist \
 -x 'seduction.asf.(?!best)' -x seduction.official \
 -x essential-skills -x .-old -x mail.root \
 -v >> $LOGFILE 2>&1 
date >> $LOGFILE
