Feature: Ability to select certain OpenCalais entities based on certain conditions

  Background:
    Given the file 'test_file_1.txt' is successfully processed


  Scenario:  Select all entities with a specific name
    When I filter on {:entity => 'EmailAddress'}
    Then the output should have 2 entries
    And All entries should be named 'EmailAddress'

  Scenario:  Select an entity with a specific value
    When I filter on {:entity => 'Event', :value => 'Meeting'}
    Then the output should have 1 entries
    And All entries should be named 'Event'
    And All entries should have the value 'Meeting'


  Scenario:  Select an entity only if another entity with a specific value exists in the data source
    When I filter on {:entity => 'Person', :given => {:entity => 'Event', :value => 'Meeting'}}
    Then the output should have 2 entries
    And All entries should be named 'Person'
    And One entry should have the value 'Roger Kay'
    And One entry should have the value 'David Bailey'