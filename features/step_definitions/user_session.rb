def admin_user
  @user ||= FactoryGirl.create(:user)
end

def admin_login
  visit path_to("home page")
  visit path_to("login page")
  page.has_content?("Username")
  page.has_content?("Password")
  fill_in "Username", :with => "testadmin"
  fill_in "Password", :with => "test123"
  click_button "Login"
  page.has_link?("Logout")
end

def customer_or_employee_login
  visit path_to("home page")
  visit path_to("ldap login")
  #visit "/tibcommunity_login/login"
  print "customer_or_employee_login"
  page.has_content?("Username")
  page.has_content?("Password")
  fill_in "Username", :with => "ninad1"
  fill_in "Password", :with => "raw123"
  click_button "Login"
  page.has_link?("Logout")
end

def public_login
  visit path_to("home page")
  page.has_link?("Login")
end

Given /^I am a "([^"]*)"$/ do |login_user|
  if  login_user == "admin"
    admin_user
  end
end

Given /^I am on the "([^"]*)"$/ do |homepage|
  visit path_to(homepage)
end

When /^I login$/ do
  admin_login
end

Then /^I should see "([^"]*)" button$/ do |button|
  page.has_content?(button)
end

Given /^I am logged in as admin$/ do
  admin_user
  admin_login
end

When /^I click "([^"]*)" button$/ do |button|
  click_link_or_button button
end

When /^I fill within "([^"]*)" with "([^"]*)" and "([^"]*)"$/ do |selector, username, password|
  within(selector) do
    fill_in "Username" , :with =>username
    fill_in "Password" , :with =>password
  end
end

Then /^I should see "([^"]*)"$/ do |result|
  case result
    when result == "Username or Password is invalid."
      within("#admin-login-wrap ") do
        page.has_content?("result")
      end
    when result == "Admin Interface"
      within("#buttons #button-link") do
        page.has_button?("Add Product")
        page.has_button?("Add Category")
        page.has_button?("Get Detailed CSV")
        page.has_button?("Get Brief CSV")
        page.has_button?("Logout")
        page.has_css?("#side-bar")
        within("#recent-updates") do
          page.has_content?("Recent Updates")
        end
      end
    when result == "TIBCO DOCS site for customer and employee"
      within("#buttons #button-link") do
        page.has_no_button?("Add Product")
        page.has_no_button?("Add Category")
        page.has_no_button?("Get Detailed CSV")
        page.has_no_button?("Get Brief CSV")
        page.has_button?("Logout")
        page.has_css?("#side-bar")
        within("#recent-updates") do
          page.has_content?("Recent Updates")
        end
      end
    else
      false
  end
end

When /^I as "([^"]*)" visit "([^"]*)" page$/ do  |login_user,login_page|
  puts login_user
  if login_user == "admin"
    visit path_to(login_page)
    puts "login_user = admin"
  elsif login_user == "customer" or login_user == "employee"
    #visit path_to("ldap login")
    visit "/tibcommunity_login/login"
  else
    false
  end

end
