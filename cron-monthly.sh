#! /bin/sh

# echo "Home directory: ${HOME} " > /tmp/a.$$
mailcurrent=mail.`date +%Y-%m`
( cd $HOME/mail/sent && ln -sf ${mailcurrent} mail.current )
touch $HOME/mail/sent/mail.current
# and fixup IMAP server subscription files
cd ${HOME}
cp .mailboxlist .mailboxlist.old.cron-monthly
find mail/spool mail/favorites mail/sent -type f -print | grep -v -f .mailboxlist >> .mailboxlist
# and unsubscribe non-existed files 
perl -i -lne 'print $_ if -f' .mailboxlist

# and fix up gnus overview files
rm -rf $HOME/News/agent/nnimap/barsook.com/mail_sent_mail/current
