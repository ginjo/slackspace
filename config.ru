require './app'

# This allows 'puts' in sinatra to work with heroku.
$stdout.sync = true

run SlackSpace::App

