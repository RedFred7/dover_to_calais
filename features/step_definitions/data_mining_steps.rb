require 'eventmachine'
require 'em-http-request'
require 'yomu'
require 'rspec'
require_relative '../../lib/dover_to_calais'
#require_relative './filtering_steps.rb'


# N.B Cucumber must be run with the Environment variable 'API_KEY' set
# to the OpenCalais API Key value.

Given(/^the file '(\w+\.\w{3,4})' is successfully processed with the rich output$/) do |file|

  steps %{
        Given  the file #{file}
        When the Output format is set to 'Application/JSON'
        And DoverToCalais processes this file
        Then the output should have no errors
        }

end

When(/^I filter the response on ({.+})$/) do  |f|
  @filtered_output = @output.filter(eval(f))

end

Then(/^The output should be an error$/) do
  @filtered_output.match(/^ERR:\s/).should_not be_nil
end


