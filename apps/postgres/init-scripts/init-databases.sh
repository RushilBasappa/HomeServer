#!/bin/bash
# docker compose exec -it postgres sh /docker-entrypoint-initdb.d/init-databases.sh

CONFIG_FILE="/docker-entrypoint-initdb.d/databases.conf"

while IFS=: read -r appvar dbvar uservar passvar; do

    # Skip empty lines or lines starting with '#'
    [[ -z "$appvar" || "$appvar" =~ ^# ]] && continue

    appname=${!appvar}
    dbname=${!dbvar}
    username=${!uservar}
    password=${!passvar}

    echo "Creating database $dbname for user $username with password $password"
    
    if ! psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT 1 FROM pg_database WHERE datname='$dbname'" | grep -q 1; then
        echo "Database $dbname does not exist, creating..."
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE USER $username WITH PASSWORD '$password';"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE $dbname;"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "GRANT ALL PRIVILEGES ON DATABASE $dbname TO $username;"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "ALTER DATABASE $dbname OWNER TO $username;"
    else
        echo "Database $dbname already exists"
    fi
done < "$CONFIG_FILE"