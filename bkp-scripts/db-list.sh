#!/bin/bash
now="$(date)"
printf "Current date and time %s\n" "$now"
save_path=/opt/backups
s3=$S3_BUCKET_URL
archive_dir=/opt/bkp-cache
env=$1
dest=$s3/$env/db

if [[ -z "$env" ]]; then
    echo "Usage: db-list.sh env" 1>&2
    exit 1
fi

#exec 1> >(logger -s -t $(basename $0)) 2>&1

cd /tmp

#### list backup files on S3 destination
duplicity  \
list-current-files  \
--archive-dir /opt/bkp-cache \
$dest

