@javascript
Feature: Adding a taxon
  As an editor of AntCat
  I want to add taxa
  So that information is kept up-to-date
  So people use AntCat

  Scenario: Adding a genus
    Given there is a subfamily "Formicinae"
    And I log in
    When I go to the edit page for "Formicinae"
    And I press "Add Genus"
    Then I should be on the new genus edit page

  Scenario: Having an error, but leave fields as user entered them
    When I log in
    And I go to the add taxon page
    And I fill in "taxon_type_taxt" with "Notes"
    And I save my changes
    Then I should see "Name name can't be blank"
    And the "taxon_type_taxt" field should contain "Notes"