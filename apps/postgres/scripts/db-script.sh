#!/bin/bash

ACTION=$1
CONFIG_FILE="/docker-entrypoint-initdb.d/databases.conf"

if [ "$ACTION" != "backup" ] && [ "$ACTION" != "restore" ]; then
  echo "Usage: $0 {backup|restore}"
  exit 1
fi

while IFS=: read -r appname dbvar uservar passvar; do
  appname=${!appname:-}
  dbname=${!dbvar:-}
  username=${!uservar:-}
  password=${!passvar:-}
  
  if [ -z "$appname" ] || [ -z "$dbname" ] || [ -z "$username" ] || [ -z "$password" ]; then
    echo "Invalid config file: $appname:$dbname:$username:$password"
    exit 1
  fi

  BACKUP_TIMESTAMP=$(TZ=${TIMEZONE} date +%Y-%m-%d)

  if [ "$ACTION" = "backup" ]; then
    mkdir -p /dumps/$appname
    PGPASSWORD=$password pg_dump -h postgres-main -U "$username" -d "$dbname" --format=plain --blobs --clean --if-exists --no-owner --no-privileges --no-tablespaces | gzip > /dumps/$appname/$appname-$BACKUP_TIMESTAMP.sql.gz
    echo "$appname backup completed"
  else
    gunzip -c "/dumps/$appname/$appname-$BACKUP_TIMESTAMP.sql.gz" | PGPASSWORD=$password psql -h postgres-main -U "$username" -d "$dbname" > /dev/null 2>&1
    echo "$appname restore completed"
  fi
done < <(sed -E '/^[[:space:]]*(#|$)/d' "$CONFIG_FILE")
