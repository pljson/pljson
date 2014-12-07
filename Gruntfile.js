'use strict';

var grunt = require('grunt');
var packageJSON = require('./package.json');

require('load-grunt-tasks')(grunt);

grunt.initConfig({
  panda: {
    docSite: {
      options: {
        pandocOptions: '-t html5 --section-divs --mathjax -s'
      },
      files: [{
        expand: true,
        flatten: true,
        src: './doc/src/*.md',
        dest: './doc/html/',
        ext: '.html'
      }]
    },
    pdf: {
      options: {
        pandocOptions: '-t latex --smart'
      },
      files: [{
        expand: true,
        cwd: './doc/src/',
        src: 'Index.md',
        dest: 'target/',
        ext: '.pdf'
      }]
    }
  },

  shell: {
    copyDiagramToSite: {
      command: 'cp ./doc/src/visual.jpg ./doc/html/'
    },

    prepareRelease: {
      command: 'rm -rf target *.zip && mkdir target && ' +
      'cp -R src/* testsuite examples *install.sql change.log readme.txt target && ' +
      'cp -R doc/html target/doc/'
    }
  },

  zip : {
    'using-cwd': {
      cwd: 'target/',
      src: ['target/**'],
      dest: 'release-' + packageJSON.version + '.zip'
    }
  }
});

grunt.registerTask('release', ['panda:docSite', 'shell:prepareRelease', 'zip']);
grunt.registerTask('buildDocSite', ['panda:docSite', 'shell:copyDiagramToSite']);
grunt.registerTask('buildPDF', ['panda:pdf']);