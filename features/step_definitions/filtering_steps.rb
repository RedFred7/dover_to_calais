require 'nokogiri'
require 'eventmachine'
require 'em-http-request'
require 'yomu'
require 'rspec'
#require File.expand_path('../../../lib/dover_to_calais', __FILE__)
require_relative '../../lib/dover_to_calais'

# N.B Cucumber must be run with the Environment variable 'API_KEY' set
# to the OpenCalais API Key value.



Given(/^the file '(\w+\.\w{3,4})' is successfully processed with the simple output$/) do |file|

  steps %{
        Given  the file #{file}
        When the Output format is set to 'Text/Simple'
        And DoverToCalais processes this file
        Then the output should have no errors
        }

end





When(/^I filter on ({.+})$/) do  |f|
  @filtered_output = @output.filter(eval(f))

end

Then(/^the output should have (\d+) entries$/) do |item_num|
  @filtered_output.size.should ==  item_num.to_i
end

Then(/^All entries should be named '(\w+)'$/) do  |name|
  @filtered_output.each do |item|
    item.name.should == name
  end

end


And(/^All entries should have the value '(\w+)'$/) do |value|
  @filtered_output.each do |item|
    item.value.match(value).should_not be_nil
  end
end


And(/^One entry should have the value '(\w+\s*\w+)'$/) do  |value|
  found = false
  @filtered_output.each do |item|
    if item.value.match(value)
       found =true
      break
    end
  end

  fail("couldn't match value '#{value}'") unless found
end

