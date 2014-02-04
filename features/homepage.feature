Feature: The TIBCO DOCs site's Homepage
  In order to generate revenue
  The users
  Should be able to visit our web site

  @homepage
  Scenario: The The TIBCO DOCS site has home page
    Given I do have a web application
    When I visit "home" page
    Then I should see the home page
    And I should see "logo" with  "Product Documentation" link within "#header-content"
    And I should see the "#side-bar" on the page
    And I should see the "#search-box" within "#side-bar"
    And I should see the "#tree-control" within "#side-bar" having link to "expand-all" and "collapse-all"
    And I should see the "#browse" within "#side-bar" to browse products category-wise
    And I should see the "#search" within "#side-bar" to browse products category-wise
    And I should see the link "Product A-Z" within "#browse"
    And I should not see a 404 page

