Feature: Able to handle wide range of data formats as input 


  @simple_output
  Scenario Outline:  Processing various data-source formats (Simple Format)
    Given  the file <input>
    When the Output format is set to 'Text/Simple'
    And DoverToCalais processes this file
    Then the output should have no errors

  Examples:
  | input |
  |test_file_1.doc |
  |test_file_1.html|
  |test_file_1.odt|
  |test_file_1.pdf|
  |test_file_1.rtf|
  |test_file_1.txt|

  @rich_output
  Scenario Outline:  Processing various data-source formats (Rich Format)
    Given  the file <input>
    When the Output format is set to 'Application/JSON'
    And DoverToCalais processes this file
    Then the output should have no errors

  Examples:
  | input |
  |test_file_1.doc |
  |test_file_1.html|
  |test_file_1.odt|
  |test_file_1.pdf|
  |test_file_1.rtf|
  |test_file_1.txt|