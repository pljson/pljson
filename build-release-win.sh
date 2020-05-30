#!/bin/bash

#type jq 2>&1 1>/dev/null
#if [ 1 -eq $? ]; then
#  echo 'Please install jq -- https://stedolan.github.io/jq/'
#  exit 1
#fi

version=$(cat package.json | ./jq.exe -r '.version')

rm -rf target pljson-*.zip 2>&1 1>/dev/null
mkdir target
cp -R src testsuite testsuite-utplsql examples install.sql uninstall.sql README.md target
sed -i -e 's/{{PLJSON_VERSION}}/'${version}'/' target/src/pljson_parser.impl.sql
cp -R docs target

cd target
zip -r -9 -v ../pljson-${version}.zip *