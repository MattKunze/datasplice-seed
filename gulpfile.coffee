_ = require 'lodash'
gulp = require 'gulp'
http = require 'http'
path = require 'path'
lr = require 'tiny-lr'
open = require 'gulp-open'
sass = require 'gulp-sass'
connect = require 'connect'
mocha = require 'gulp-mocha'
gutil = require 'gulp-util'
clean = require 'gulp-clean'
rename = require 'gulp-rename'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
embedlr = require 'gulp-embedlr'
refresh = require 'gulp-livereload'
minifycss = require 'gulp-minify-css'
browserify = require 'gulp-browserify'
server = do lr

fileset = (base) ->
  base: base
  images: "#{base}/images"
  scripts: "#{base}/src/"
  styles: "#{base}/styles"

browserifyOptions =
  debug: not gutil.env.production
  transform: ['coffeeify']
  extensions: ['.coffee']   # extension to skip when calling require()

app = fileset './app'
build = './build'
dist = fileset "#{build}/dist"
test = fileset "#{build}/test"
port = 3000
# allow to connect from anywhere
hostname = null

# Starts the webserver
gulp.task 'webserver', ->
  application = connect()
    # allows import of npm/bower resources
    .use(connect.static path.resolve './node_modules')
    .use(connect.static path.resolve './bower_components')
    # Mount the mocha tests
    .use(connect.static path.resolve "#{test.base}")
    # Mount the app
    .use(connect.static path.resolve "#{dist.base}")
    .use(connect.directory path.resolve "#{dist.base}")
  (http.createServer application).listen port, hostname

# Copies images to dest then reloads the page
gulp.task 'images', ->
  (gulp.src "#{app.images}/**/*")
    .pipe(gulp.dest "#{dist.images}")
    .pipe(refresh server)

gulp.task 'scripts', ->
  (gulp.src "#{app.scripts}/index.coffee", read: false)
    .pipe(browserify browserifyOptions).on('error', gutil.log)
    .pipe(rename 'index.js')
    .pipe(if gutil.env.production then uglify() else gutil.noop())
    .pipe(gulp.dest "#{dist.scripts}")
    .pipe(refresh server)

gulp.task 'test-scripts', ['scripts'], ->
  (gulp.src "#{app.scripts}/test.coffee", read: false)
    .pipe(browserify browserifyOptions).on('error', gutil.log)
    .pipe(rename 'test.js')
    .pipe(gulp.dest "#{test.scripts}")
    .pipe(refresh server)

# Compiles Sass files into css file
# and reloads the styles
gulp.task 'test-styles', ->
  (gulp.src "#{app.styles}/test.scss")
    # TODO: should include pattern for styles from React components
    .pipe(sass includePaths: ['styles/includes']).on('error', gutil.log)
    .pipe(concat 'test.css')
    .pipe(gulp.dest "#{test.styles}")
    .pipe(refresh server)

# Compiles Sass files into css file
# and reloads the styles
gulp.task 'styles', ->
  (gulp.src "#{app.styles}/index.scss")
    # TODO: should include pattern for styles from React components
    .pipe(sass includePaths: ['styles/includes']).on('error', gutil.log)
    .pipe(rename 'index.css')
    .pipe(if gutil.env.production then minifycss() else gutil.noop())
    .pipe(gulp.dest "#{dist.styles}")
    .pipe(refresh server)

# Copy the HTML to dist
gulp.task 'html', ->
  (gulp.src "#{app.base}/index.html")
    # embeds the live reload script
    .pipe(if gutil.env.production then gutil.noop() else embedlr())
    .pipe(gulp.dest "#{dist.base}")
    .pipe(refresh server)

# Copy the HTML to mocha
gulp.task 'test-html', ->
  (gulp.src "#{app.base}/test.html")
    # embeds the live reload script
    .pipe(embedlr())
    .pipe(gulp.dest "#{test.base}")
    .pipe(refresh server)

gulp.task 'livereload', ->
  server.listen 35729, (err) ->
    return (console.log err) if err

# Watches files for changes
gulp.task 'watch', ->
  gulp.watch "#{app.images}/**", ['images']
  gulp.watch "#{app.scripts}/**", ['scripts', 'test-scripts']
  gulp.watch "#{app.styles}/**", ['styles', 'test-styles']
  gulp.watch "#{app.base}/index.html", ['html']
  gulp.watch "#{app.base}/test.html", ['test-html']

# Opens the app in your browser
gulp.task 'browse', ->
  options = url: "http://localhost:#{port}"
  gulp.src("#{dist.base}/index.html")
    .pipe(open("", options))

gulp.task 'clean', ->
  (gulp.src "#{build}", read: false)
    .pipe(clean force: true)

gulp.task 'build-dist', ['html', 'images', 'styles', 'scripts']
gulp.task 'build-test', ['test-html', 'test-styles', 'test-scripts']

gulp.task 'test', ->
  (gulp.src "#{app.scripts}/test.coffee", read: false)
    .pipe(browserify browserifyOptions).on('error', gutil.log)
    .pipe(mocha reporter: 'nyan').on('error', gutil.log)

do (
  serverOpts = ['build', 'webserver', 'livereload', 'watch']
) ->
  serverOpts.push 'browse' if gutil.env.open
  gulp.task 'server', serverOpts

gulp.task 'build', ['build-dist', 'build-test']

# https://github.com/gulpjs/gulp/blob/master/docs/API.md#async-task-support
gulp.task 'default', ['clean', 'build']
