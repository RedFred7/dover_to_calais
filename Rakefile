require "bundler/gem_tasks"
require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  if ENV['TAGS']
    t.cucumber_opts = "features --format pretty API_KEY=#{ENV['API_KEY']} --tags #{ENV['TAGS']}"

  else
    t.cucumber_opts = "features --format pretty API_KEY=#{ENV['API_KEY']}"

  end
  
end
