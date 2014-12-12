module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    watch:
      scripts:
        files: 'static/coffee/*.coffee'
        tasks: ['coffee']
    coffee:
      compile:
        options:
          bare:  true
          sourceMap: true
        files:
          'static/js/main.js':
            ['static/coffee/spinner.coffee'
            ,'static/coffee/main.coffee'
            ]

  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.registerTask("default", "coffee")
