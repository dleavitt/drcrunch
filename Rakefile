require 'sinatra/asset_pipeline/task'
require 'mongoid/tasks/database'

spec = Gem::Specification.find_by_name 'mongoid'
load "#{spec.gem_dir}/lib/mongoid/tasks/database.rake"
require_relative 'app'

Sinatra::AssetPipeline::Task.define! DrCrunch

task :environment do
  require_relative 'app'
end
