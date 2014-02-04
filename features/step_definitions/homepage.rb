def path_to(page_name)

  case page_name
    when /root page/
      '/'
    when /home page/,/home/
      '/'
    when /login page/,/login/
      '/login'
    when /ldap login/ #,/customer login/,/employee login/
      '/tibcommunity_login/login'
    when /products/
      '/products'
    when /search_tab/
      '/products/search_tab'
    when /a_z_products/
      'products/a_z_products'
    when /new category/
      '/categories/new'
    when /new product page/
      '/products/new'
    when /new document/
      '/documents/new'
    when /edit category/
      '/category/edit'
    when /edit product/
      '/category/edit'
    when /edit document/
      '/category/edit'
    when /product show/
      'product_path'
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
                "Now, go and add a mapping in #{__FILE__}"
  end
end

Given /^I do have a web application$/ do
end

Then /^I should see the home page$/ do
  root_path
end

Then /^I should not see a (\d+) page$/ do |arg1|
  root_path
end


Then /^I should see "([^"]*)" with  "([^"]*)" link within "([^"]*)"$/ do|logo,link, selector|
  within(selector) do
  puts page.should have_selector(".#{logo}")
    page.has_link?(link)
  end
end

#=======================================================================================================================
#Given /^I go to login page$/ do
#  visit "/login"
#  #print page.html
#end
#
#When /^I login in as ([^"]*) with password ([^"]*)$/ do |username,password|
#  within("#new_user_session") do
#    fill_in 'user_session_username', :with=> "#{username}"
#    fill_in 'user_session_password', :with=> "#{password}"
#  end
#end
#
#When /^I click on "([^"]*)" button$/ do |button|
#  click_button 'Login'
#  #print page.status_code
#  #page.response_headers
#end
#
#Then /^I should see all the  products in admin interface$/ do
#  visit products_path
#  #page.should have_content("login uncessfull")
#  puts page.status_code
#  #print page.response_headers
#  #print page.html
#end
