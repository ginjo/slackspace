# Load app.
require './app'

# This allows 'puts' in sinatra to work with heroku.
$stdout.sync

# Run app.
run App