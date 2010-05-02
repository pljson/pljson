#!/bin/sh

version=$1
echo "Creating new release: ${version}"
echo "Naming standard should be json_v08_5.zip"

archivename="json_v${version}"
zip ${archivename} *.sql *.typ change.log readme.txt
cp tex/main.pdf doc.pdf
zip ${archivename} doc.pdf
zip ${archivename} testsuite/*.sql examples/*.sql addons/*.sql
