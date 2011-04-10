Feature: Logging in
  As a user of AntCat
  I want to be able to log in
  So I can edit references

  Scenario: Logging in succesfully
    Given the following user exists
      |email            |password|
      |email@example.com|secret  |
    Given I am not logged in
    When I go to the main page
      And I follow "Login"
      And I fill in "user_email" with "email@example.com"
      And I fill in "user_password" with "secret"
      And I press "Go" within "#login"
    Then I should be on the main page

  Scenario: Logging in unsuccesfully
    Given the following user exists
      |email            |password|
      |email@example.com|secret  |
    Given I am not logged in
    When I go to the main page
      And I follow "Login"
      And I fill in "user_email" with "email@example.com"
      And I fill in "user_password" with "asd;fljl;jsdfljsdfj"
      And I press "Go" within "#login"
    Then I should be on the sign in page
      And I should see "AntCat"
