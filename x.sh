#! /bin/bash

# run indexes
# debug="-r debug"
ruby1.8 ${debug} ${HOME}/bin.shared/index-mail \
 -m ~/mail -o ~/mail.index \
 -s spool -s favorites -s sent -s archive -s unread \
 -c ~/fulltext/conf/mknmzrc.mail -t namazu \
 -x zappy -x mindlist -x nlptalk -x junk -x craigslist \
 -x 'seduction.asf.(?!best)' -x seduction.official \
 -x essential-skills -x .-old -x mail.root \
 -v   

