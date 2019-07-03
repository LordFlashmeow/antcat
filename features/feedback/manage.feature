Feature: Managing user feedback
  As an AntCat editor
  I want to open/close user feedback items
  So that editors can track issues

  Background:
    Given I log in as a catalog editor named "Archibald"

  Scenario: Closing a feedback item (with feed)
    Given a visitor has submitted a feedback

    When I go to the most recent feedback item
    Then I should see "This feedback item is still open"
    And I should not see "Re-open"

    When I follow "Close"
    Then I should see "Successfully closed feedback item."
    And I should see "Re-open"
    And I should not see "This feedback item is still open"

    When I go to the activity feed
    Then I should see "Archibald closed the feedback item #"

  Scenario: Re-opening a closed feedback item (with feed)
    Given there is a closed feedback item

    When I go to the most recent feedback item
    Then I should see "Re-open"
    And I should not see "This feedback item is still open"

    When I follow "Re-open"
    Then I should see "Successfully re-opened feedback item."
    And I should see "This feedback item is still open"
    And I should not see "Re-open"

    When I go to the activity feed
    Then I should see "Archibald re-opened the feedback item #"
