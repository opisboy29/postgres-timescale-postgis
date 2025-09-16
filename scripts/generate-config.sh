#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Generate pgcat.toml from template
envsubst < pgcat/pgcat.toml.template > pgcat/pgcat.toml

echo "Configuration files generated successfully!" 