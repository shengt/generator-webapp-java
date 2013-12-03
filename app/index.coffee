util = require 'util'
path = require 'path'
yeoman = require 'yeoman-generator'

WebappJavaGenerator = module.exports = (args, options, config) ->
  yeoman.generators.Base.apply(@, arguments)

  # setup the test-framework property, Gruntfile template will need this
  @testFramework = options['test-framework'] or 'mocha'
  @coffee = options.coffee

  # for hooks to resolve on mocha by default
  options['test-framework'] = @testFramework

  # resolved to mocha by default (could be switched to jasmine for instance)
  @hookFor 'test-framework', { as: 'app' }

  @mainCoffeeFile = 'console.log "\'Allo from CoffeeScript!"'

  @on 'end', () ->
    @installDependencies
      skipInstall: options['skip-install']
      skipMessage: options['skip-install-message']

  @pkg = JSON.parse @readFileAsString path.join __dirname, '../package.json'

  console.log 'Run this generator at the root of the web project.'
  console.log 'For maven java web project, webapp path should be "src/main/webapp".'
  console.log 'For normal java web project, webapp path should be "WebContent"'

util.inherits WebappJavaGenerator, yeoman.generators.Base

WebappJavaGenerator.prototype.askFor = () ->
  cb = @async()

  # have Yeoman greet the user.
  if @options['skip-welcome-message']
    console.log @yeoman
    console.log 'Out of the box I include HTML5 Boilerplate and jQuery.'

  prompts = [{
    name: 'webappPath'
    message: 'Where is your webapp path related to the current folder?'
    default: 'src/main/webapp'
  }, {
    type: 'confirm'
    message: 'Would you like to support old IE (6-8)?'
    name: 'oldIE'
    default: true
  }, {
    type: 'list'
    message: 'What css precompiler would you like to use?'
    name: 'cssPrecompiler'
    choices: [{
      name: 'Stylus'
      value: 'stylus'
      default: true
    }, {
      name: 'Less'
      value: 'less'
    }]
  }, {
    type: 'confirm'
    message: 'Would you like this web app to be responsive?'
    name: 'includeResponsive'
    default: true
  }, {
    type: 'checkbox'
    message: 'What MV* framework would you like?'
    name: 'mvcFramework'
    choices: [{
      name: 'Backbone'
      value: 'backbone'
      default: false
    }, {
      name: 'AngularJs'
      value: 'angular'
      default: false
    }]
  }, {
    type: 'checkbox'
    message: 'What more would you like?'
    name: 'features'
    choices: [{
      name: 'Bootstrap'
      value: 'bootstrap'
      checked: true
    }, {
      name: 'Modernizr'
      value: 'includeModernizr'
      checked: true
    }]
  }]

  @prompt prompts, (answers) =>
    @webappPath = path.join __dirname, answers.webappPath
    @mkdir @webappPath

    hasFeature = (feat, list) -> list.indexOf(feat) isnt -1

    cssPrecompilers = answers.cssPrecompiler
    @less = hasFeature 'less', cssPrecompilers
    @stylus = hasFeature 'stylus', cssPrecompilers

    @oldIE = answers.oldIE

    @includeResponsive = answers.includeResponsive

    mvcFramework = answers.mvcFramework
    @angular = hasFeature 'angular', mvcFramework
    @backbone = hasFeature 'backbone', mvcFramework

    features = answers.features

    @bootstrap = hasFeature 'bootstrap', features
    @includeModernizr = hasFeature 'includeModernizr', features

    cb()

WebappJavaGenerator.prototype.gruntfile = () ->
  @template 'Gruntfile.js'

WebappJavaGenerator.prototype.packageJSON = () ->
  @template '_package.json', 'package.json'

WebappJavaGenerator.prototype.git = () ->
  @copy 'gitignore', '.gitignore'
  @copy 'gitattributes', '.gitattributes'

WebappJavaGenerator.prototype.bower = () ->
  @copy 'bowerrc', '.bowerrc'
  @copy '_bower.json', 'bower.json'

WebappJavaGenerator.prototype.jshint = () ->
  @copy 'jshintrc', '.jshintrc'

WebappJavaGenerator.prototype.editorConfig = () ->
  @copy 'editorconfig', '.editorconfig'

WebappJavaGenerator.prototype.mainStylesheet = () ->
  if @bootstrap
    @copy 'main.styl', "#{@webapp}/styles/main.styl}"
  else
    @copy 'main.css', "#{@webapp}/styles/main.css'}"

WebappJavaGenerator.prototype.writeIndex = () ->

  @indexFile = @readFileAsString path.join @sourceRoot(), 'index.html'
  @indexFile = @engine @indexFile, @
  @indexFile = @appendScripts @indexFile, 'scripts/main.js', [
    'scripts/main.js'
  ]

  if @coffee
    @indexFile = @appendFiles
      html: @indexFile
      fileType: 'js'
      optimizedPath: 'scripts/coffee.js'
      sourceFileList: ['scripts/hello.js']
      searchPath: '.tmp'

WebappJavaGenerator.prototype.app = () ->
  @mkdir 'app'
  @mkdir 'app/scripts'
  @mkdir 'app/styles'
  @mkdir 'app/images'
  @write 'app/index.html', @indexFile

  if @coffee
    @write 'app/scripts/hello.coffee', @mainCoffeeFile

  @write 'app/scripts/main.js', 'console.log(\'\\\'Allo \\\'Allo!\');'
