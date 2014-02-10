
require 'nokogiri'
require 'eventmachine'
require 'em-http-request'
require 'yomu'
require 'rspec'
require File.expand_path('../../../lib/dover_to_calais', __FILE__)


# N.B Cucumber must be run with the Environment variable 'API_KEY' set
# to the OpenCalais API Key value.


Given(/^the file (\w+\.\w{3,4})$/) do |arg1|
  puts arg1
 @input = Dir.pwd + '/test/' + arg1
  @output = nil
end



When(/^DoverToCalais processes this file$/) do
  EM.run {

    DoverToCalais::API_KEY =  ENV['API_KEY']
    d1 =  DoverToCalais::Dover.new(@input)
    d1.analyse_this
    d1.to_calais do |response|
      @output = response
      EM.stop
    end

  }
end



Then(/^the output should have no errors$/) do
   @output.error.should be_nil
end