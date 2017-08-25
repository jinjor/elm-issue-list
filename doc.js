const fs = require('fs');

if (!fs.existsSync('./elm-stuff')) {
  console.error('Cannot find ./elm-stuff directory.');
  process.exit(1);
}

const json = JSON.parse(fs.readFileSync('./elm-stuff/exact-dependencies.json', 'utf8'));

const toUrl = (pkg, version) => `http://package.elm-lang.org/packages/${pkg}/${version}`

const ul = Object.keys(json).map(pkg => {
  const version = json[pkg];
  const text = `${pkg}/${version}`;
  const url = toUrl(pkg, version);
  return `<li><a href="${url}">${text}</a></li>`;
}).reduce((memo, a) => memo + "\n" + a, '<ul>') + '\n</ul>';

const html = `<head><meta http-equiv="content-language" content="en"><head><body>${ul}</body>`;

const outFile = './elm-stuff/generated-code/libs.html';
fs.writeFileSync(outFile, html);

console.log(outFile);
