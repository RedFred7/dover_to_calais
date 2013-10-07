Feature: Able to handle wide range of data formats as input
  Scenario Outline:  Processing various data-source formats
    Given  the file <input>
    When DoverToCalais processes this file
    Then the output should have no errors

  Examples:
  | input |
  |test_file_1.doc |
  |test_file_1.html|
  |test_file_1.odt|
  |test_file_1.pdf|
  |test_file_1.rtf|
  |test_file_1.txt|
