'use strict';

var grunt = require('grunt');
var packageJSON = require('./package.json');

require('load-grunt-tasks')(grunt);

grunt.initConfig({
  shell: {
    genPDF: {
      command: 'cd tex && pdflatex main.tex && mv main.pdf doc.pdf'
    },

    prepareRelease: {
      command: 'rm -rf target *.zip && mkdir target && ' +
      'cp -R src/* testsuite examples tex/doc.pdf change.log readme.txt target'
    }
  },

  zip : {
    'using-cwd': {
      cwd: 'target/',
      src: ['target/*'],
      dest: 'release-' + packageJSON.version + '.zip'
    }
  }
});

grunt.registerTask('release', ['shell:genPDF', 'shell:prepareRelease', 'zip']);