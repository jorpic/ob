module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    watch:
      scripts:
        files: 'coffee/*.coffee'
        tasks: ['coffee']
    coffee:
      compile:
        options:
          bare:  true
          sourceMap: true
        files:
          'static/main.js': ['coffee/*.coffee']

  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.registerTask("default", "coffee")
