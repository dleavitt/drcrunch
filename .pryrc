# Loads the app environment when using pry
require "./app"

app = DrCrunch

def reload!
  load 'app.rb'
  # Dir['./lib/**/*.rb'].each(&method(:load))
end
