#!/bin/bash

# sass --style compressed src/bulma-custom.sass src/generated/bulma-custom.css &&
# npm run build &&
# rm -rf ./docs &&
# mv build docs &&
# sed -i '' -e 's/\"\//\"\.\//g' docs/index.html

mkdir src/generated 2>/dev/null
docker-compose run sass
docker-compose run yarn build
