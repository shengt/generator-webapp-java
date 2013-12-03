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
  console.log 'For maven Java web project, webapp path should be "src/main/webapp".'
  console.log 'For normal Java web project, webapp path should be "WebContent"'

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
    @webappPath = answers.webappPath
    console.log path.join __dirname, @webappPath

    cssPrecompilers = answers.cssPrecompiler
    @less = 'less' in cssPrecompilers
    @stylus = 'stylus' in cssPrecompilers

    @oldIE = answers.oldIE

    @includeResponsive = answers.includeResponsive

    mvcFramework = answers.mvcFramework
    @angular = 'angular' in mvcFramework
    @backbone = 'backbone' in mvcFramework

    features = answers.features
    @bootstrap = 'bootstrap' in features
    @includeModernizr = 'includeModernizr' in features

    cb()

WebappJavaGenerator.prototype.gruntfile = () ->
  @template 'Gruntfile.js'

WebappJavaGenerator.prototype.packageJSON = () ->
  @template '_package.json', 'package.json'

WebappJavaGenerator.prototype.git = () ->
  @copy 'gitignore', '.gitignore'
  @copy 'gitattributes', '.gitattributes'

WebappJavaGenerator.prototype.bower = () ->
  @template 'bowerrc', '.bowerrc'
  @template '_bower.json', 'bower.json'

WebappJavaGenerator.prototype.jshint = () ->
  @copy 'jshintrc', '.jshintrc'

WebappJavaGenerator.prototype.editorConfig = () ->
  @copy 'editorconfig', '.editorconfig'

WebappJavaGenerator.prototype.mainStylesheet = () ->
  if @bootstrap
    @copy 'main.styl', "#{@webappPath}/styles/main.styl"
  else if @less
    @copy 'main.less', "#{@webappPath}/styles/main.less"

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
  @mkdir "#{@webappPath}"
  @mkdir "#{@webappPath}/scripts"
  @mkdir "#{@webappPath}/styles"
  @mkdir "#{@webappPath}/images"
  @write "#{@webappPath}/index.html", @indexFile

  if @coffee
    @write "#{@webappPath}/scripts/hello.coffee", @mainCoffeeFile

  @write "#{@webappPath}/scripts/main.js", 'console.log(\'\\\'Allo \\\'Allo!\');'
