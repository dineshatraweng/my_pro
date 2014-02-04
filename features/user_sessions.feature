@user_session
Feature: User Sessions
  So that I can browse TIBCO DOCS
  As an admin and registered employee/customer user
  I want to log in and log out

  @admin_login
  Scenario: Admin login
    Given I am a "admin"
    And I am on the "home page"
    When I login
    Then I should see "Logout" button

  @admin_logout
  Scenario:Admin logout
    Given I am logged in as admin
    And I am on the "home page"
    When I click "Logout" button
    Then I should see "Login" button

  @login_scenario
  Scenario Outline: Login Scenario Of Different  site user
    Given I am a "<user>"
    And I visit "home page" page
    When I as "<user>" visit "login" page
    And I fill within "<form>" with "<username>" and "<password>"
    When I click "<button>" button
    Then I should see "<output>"

  Examples:
  |user         | username  | password   | form    | button   | output  |
  |admin        | abcabc    | qqqq      |#admin-login-wrap #new_user_session   |  Login  | Username or Password is invalid. |
  |admin        | abcabc    | test123   |#admin-login-wrap #new_user_session   |  Login  | Username or Password is invalid. |
  |admin        | rawadmin  | qqqq      |#admin-login-wrap #new_user_session   | Login   | Username or Password is invalid. |
  |admin        | rawadmin  | test123   |#admin-login-wrap #new_user_session   |  Login  | Admin Interface |

  |customer     | rawadmin  | test123   |#login-wrap #partners-and-customers-login   |  Login  | Username or Password is invalid.|
  |customer     | abcabc    | defdefg   |#login-wrap #partners-and-customers-login   |  Login  | Username or Password is invalid.|
  |customer     | ninaad1   | raw123    |#login-wrap #partners-and-customers-login   |  Login  | TIBCO DOCS site customer and employee|

  |employee     | rawadmin  | test123   |#login-wrap #employee-login   |  Login  | Username or Password is invalid.|
  |employee     | abcabc    | defdefg   |#login-wrap #employee-login   |  Login  | Username or Password is invalid. |
  |employee     | ninaad1   | raw123    |#login-wrap #employee-login   |  Login  | TIBCO DOCS site customer and employee |

