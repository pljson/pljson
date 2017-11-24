#!/bin/bash

type node 2>&1 1>/dev/null
if [ 1 -eq $? ]; then
  echo 'Please install node.js -- https://nodejs.org'
  exit 1
fi

version=$(node -pe 'JSON.parse(require("fs").readFileSync(process.argv[1])).version' package.json)

rm -rf target *.zip 2>&1 1>/dev/null
mkdir target
cp -R src/* testsuite examples *install.sql CHANGELOG.md README.md target
cp -R docs target

cd target
zip -r -9 -v ../pljson-${version}.zip *
