set version=1.5.19

java -cp pldoc-%version%-jar-with-dependencies.jar net.sourceforge.pldoc.PLDoc -ignoreinformalcomments -showSkippedPackages -d docs/api -doctitle 'PL/JSON' -overview docs_overview.html src/*.decl.sql src/addons/*.decl.sql
