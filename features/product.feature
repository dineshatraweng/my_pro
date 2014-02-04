Feature:The Product features
  In order see products
  The users
  Should be able to visit products page

  @products_page
  Scenario: The site has a products page to list products
    Given The site has some products page
    Given The site has "products" page
    When I visit the "products" page
    Then I should see the products
    And I should not see a 404 page

  @product_az
  Scenario: The a-z product listing feature
    Given The site has some products
    Given I visit "products" page
    When I click on "Products A-Z" link
    Then I should see the A-Z Product listing
    When I select one of product
    Then I should see the "product show" page

  @products_scenario
  Scenario Outline: When admin logged in ,he should see all the product.When user login,then they should see all product except admin products
    Given I have "<type>" products
    Given I visit "home" page
    When I login as "<user>"
    Then I should see "<elements>" on the current page
    And I should see "<type>" products

  Examples:
  |user         | elements              | type          |
  |admin        |#recent-updates        | admin         |
  |admin        |#recent-updates        | require_login |
  |admin        |#recent-updates        | public        |

  |customer_or_employee | #recent-updates | require_login|
  |customer_or_employee | #recent-updates | public       |

  |public       | #recent-updates       | public|


  @product_features
    Scenario Outline: The Product show page after various type of login(admin,customer/employee,public)
     Given I have "<type>" products
     And I visit "home" page
     When I login as "<user>"
     Then I visit "home page" page
     When I click on "product" link
     Then As a "<user>" I should see the "<type>" product page

  Examples:
   |user         | type          |
   |admin        | admin         |
   |admin        | require_login |
   |admin        | public        |

    |customer_or_employee | require_login|
   |customer_or_employee | public       |

   |public       | public|
