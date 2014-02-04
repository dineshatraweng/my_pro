Feature:The Search features
  In order to do search
  The users
  Should be able to visit our site search page
  @current
  Scenario: The site has a search page
    Given I visit "search_tab" page
    When I enter "tibco" in the search page
    Then I should see the search results
    And I should not see a 404 page

  @product_find
  Scenario: The product find autocomplete feature
    Given I have some products
    Given I visit "home page" page
    When I enter "tibco" within "quick-find" page
    Then I should see the autocomplete options
    When I select one of autocomplete item
    When I press "search" button
    Then I should see the products with text "tibco" in listing
