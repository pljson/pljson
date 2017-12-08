#!/bin/bash

version=1.5.19

[ ! -f pldoc-${version}.jar ] && curl -o pldoc-${version}.jar \
  https://oss.sonatype.org/content/repositories/releases/net/sourceforge/pldoc/pldoc/${version}/pldoc-${version}-jar-with-dependencies.jar

[ ! -d docs/api ] && mkdir -p docs/api

java -cp pldoc-${version}.jar net.sourceforge.pldoc.PLDoc \
  -ignoreinformalcomments \
  -showSkippedPackages \
  -d docs/api \
  -doctitle 'PL/JSON' \
  -overview docs_overview.html \
  src/*.decl.sql src/addons/*.decl.sql
