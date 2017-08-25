elm-app build &&
rm -rf ./docs &&
cp -r build docs &&
sed -i '' -e 's/\"\//\"\.\//g' docs/index.html
