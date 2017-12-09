#!/bin/bash

mkdir src/generated 2>/dev/null

set -e

docker-compose run sass
docker-compose run yarn build
sed -i '' -e 's/\"\//\"\.\//g' docs/index.html
