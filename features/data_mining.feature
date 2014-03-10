  Feature: Ability to detect relationships between entities and events

  Background:
    Given the file 'test_file_1.txt' is successfully processed with the rich output  

    @rich_output
    Scenario:  Filter an entity with the rich output format
    When I filter the response on {:entity => 'Event', :value => 'Meeting'}
    Then The output should be an error
  