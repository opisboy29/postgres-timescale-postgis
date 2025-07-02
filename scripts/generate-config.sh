#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Generate pgbouncer.ini from template
envsubst < pgbouncer/pgbouncer.ini.template > pgbouncer/pgbouncer.ini

# Generate userlist.txt
echo "\"${POSTGRES_USER}\" \"${POSTGRES_PASSWORD}\"" > pgbouncer/userlist.txt

echo "Configuration files generated successfully!" 