require "bundler/gem_tasks"
require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  if ENV['TAGS'].empty?
    t.cucumber_opts = "features --format pretty API_KEY=#{ENV['API_KEY']}"
  else
    t.cucumber_opts = "features --format pretty API_KEY=#{ENV['API_KEY']} --tags #{ENV['TAGS']}"
  end
  
end
