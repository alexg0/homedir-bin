#! /bin/bash
#
# archive all my mail
# 
# TODO: alexg: move deleted messages into separate files

export TMPDIR=~/tmp TMP=~/tmp

cd ${HOME}/mail

# dryrun=-n
# verbose=-v
# chmod +t ${HOME}

# create backup of spool dir
# date=`date --iso=date`
# echo -n "backup up spool.."
# tar czf backup/spool-backup-${date}.tar.gz spool
# echo ".done"

output_dir=expired/$(date +%Y)
[[ -d $output_dir ]] || mkdir $output_dir || exit 1
opt="${dryrun} ${verbose} -o ${output_dir} -s .%Y-%m -u -p"
 
for prefix in mail list junk; do
   extraopt=
   case "$prefix" in
     mail) 
	   days=180
	   extraopt=--no-compress
	   ;;
     list) 
	   days=60
	   ;;
     junk) 
	   days=8
	   extraopt=--delete
	   ;;
     *)
	   echo "Unknown prefix $prefix"
	   exit 1
	   ;;
   esac

   nice archivemail ${opt} -d ${days} ${extraopt} spool/${prefix}.*

done

# fixup gnus caching
rm -rf ${HOME}/News/agent/nnimap/barsook.com/mail_spool_*

# re-enable mail spooling
# chmod -t ${HOME}

# fix subscriptions
${HOME}/bin.shared/cron-monthly.sh
