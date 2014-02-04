

Given /^I visit "([^"]*)" page$/ do |page_name|
  visit path_to(page_name)
end

When /^I enter "([^"]*)" in the search page$/ do |arg1|
  page.find_by_id("search-box-gsa") do
    fill_in "big-find", :with=> arg1
    click_button "search-button"
  end
  #puts page.response_headers
end

Then /^I should see the search results$/ do
  current_path.should == search_tab_products_path
  #puts page.response_headers
  #puts page.body
end

#@product_find
When /^I enter "([^"]*)" within "([^"]*)" page$/ do |string, selector|
  within("#side-bar #search-box") do
    within("#find_product_name_input") do
      fill_in "#{selector}", :with=> string
    end
  end
end
#@product_find
Then /^I should see the autocomplete options$/ do
  current_path.should == "/"
  page.has_css?('.ui-menu-item')
  page.has_css?('ul.ui-autocomplete ui-menu ui-widget ui-widget-content ui-corner-all')
end
#@product_find
When /^I select one of autocomplete item$/ do
  current_path.should == "/"
  page.has_content?('tibco')
  within('ul.ui-autocomplete ui-menu ui-widget ui-widget-content ui-corner-all') do
    page.has_content?("li.ui-menu-item")
  end
end

#@product_find
When /^I press "([^"]*)" button$/ do |arg1|
  within("#side-bar #search-box") do
    click_button "search-button"
  end
end

Then /^I should see the products with text "([^"]*)" in listing$/ do |text|
  within('#product-cluster') do
    page.has_content?(text)
  end
end
