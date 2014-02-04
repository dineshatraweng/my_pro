Feature:The sidebar features
  In order see products
  The users
  Should be able to visit products page

  @sidebar
  Scenario: The sidebar list the products category wise
   Given The site has some products
   When I visit "products" page
   Then I should see the "#side-bar" on the page
   Then I should see the "#search-box" within "#side-bar"
   Then I should see the "#tree-control" within "#side-bar" having link to "expand-all" and "collapse-all"
   Then I should see the "#browse" within "#side-bar" to browse products category-wise
   Then I should see the link "Product A-Z" within "#browse"
   When I click on "expand-all" link within "#tree-control"
   Then I should see all the products within "#browse"
   When I click on "collapse-all" link within "#tree-control"
   Then I should only see the categories within "#browse"

  @admin
  Scenario: The admin interface
   Given The site has some products.
   Given The site also has documents