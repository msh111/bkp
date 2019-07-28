#!/bin/bash
set -e
now="$(date)"
printf "Current date and time %s\n" "$now"
save_path=/opt/backups
s3=$S3_BUCKET_URL
archive_dir=/opt/bkp-cache
dest=$s3/$APP_ENV/db

# Don't backup databases with these names 
# Example: starts with mysql (^mysql) or ends with _schema (_schema$)
IGNORE_DB="(^mysql|_schema$)"

# cd $save_path
# chown $MYSQL_DATABASE $save_path


#==============================================================================
# METHODS
#==============================================================================

function hr(){
  printf '=%.0s' {1..100}
  printf "\n"
}

function echo_status(){
  printf '\r'; 
  printf ' %0.s' {0..100} 
  printf '\r'; 
  printf "$1"'\r'
}

function mysql_login() {
  local mysql_login="-h $DB_HOST -u $MYSQL_USER" 
  if [ -n "$MYSQL_PASSWORD" ]; then
    local mysql_login+=" -p$MYSQL_PASSWORD" 
  fi
  echo $mysql_login
}
function database_list() {
  local show_databases_sql="SHOW DATABASES WHERE \`Database\` NOT REGEXP '$IGNORE_DB'"
  echo $(mysql $(mysql_login) -e "$show_databases_sql"|awk -F " " '{if (NR!=1) print $1}')
}

function backup_database(){
    backup_file="$save_path/$database.sql" 
    output+="$database => $backup_file\n"
    echo_status "...backing up $count of $total databases: $database"
    mysqldump $(mysql_login) $database > $backup_file
}

function backup_databases(){
  local databases=$(database_list)
  local total=$(echo $databases | wc -w | xargs)
  local output=""
  local count=1
  for database in $databases; do
    backup_database
    local count=$((count+1))
  done
  echo -ne $output | column -t
  echo -e "\nAll databases dump complete!"
}


function upload(){
echo -e "Upload to S3"

#### Upload to S3
duplicity \
--include $save_path \
--exclude '**' \
--allow-source-mismatch \
--full-if-older-than 6M \
--s3-use-ia \
--volsize 4000 \
--no-encryption \
--s3-use-server-side-encryption \
--no-compression \
--archive-dir $archive_dir \
--s3-multipart-chunk-size 100 \
--s3-multipart-max-procs 1 \
--s3-european-buckets \
--s3-use-new-style \
/ $dest
}

function maintenace(){
#### Maintenance job for deleting old incremental files
echo -e "\nMaintenance job for deleting old incremental files"
duplicity remove-all-inc-of-but-n-full 4 --archive-dir /opt/bkp-cache --force $dest
duplicity remove-all-but-n-full 16 --archive-dir /opt/bkp-cache --force  $dest
}

#==============================================================================
# RUN SCRIPT
#==============================================================================
hr
mkdir -p $save_path
backup_databases
hr
echo -e "\n####List files to upload"
ls -lah $save_path
hr
upload
hr
maintenace

