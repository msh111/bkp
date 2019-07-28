#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
dbname=$1
env=$2
now="$(date)"
printf "Current date and time %s\n" "$now"
save_path=/opt/backups
s3=$S3_BUCKET_URL
archive_dir=/opt/bkp-cache
dest=$s3/$env/db

if [[ ( -z "$dbname" ) || ( -z "$env" ) ]]; then
    echo "Must provide database and env, example: db-restore.sh mydb env04" 1>&2
    exit 1
fi

# Linux bin paths
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"

mkdir -p $save_path

echo -e "\n#### Download"
duplicity \
--file-to-restore opt/backups \
$dest \
$save_path/ \
--no-encryption \
--verbosity info \
--archive-dir /opt/bkp-cache \
--force

echo -e "\n#### Set permissions for folder"
cd $save_path

echo -e "\n####List files to restore"
ls -la 

echo -e "\n#### Starting db restore"
mysql -h $DB_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $dbname < $save_path/$dbname.sql
