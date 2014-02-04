
Given /^The site has some products$/ do
  create_products
end

Then /^I should see the "([^"]*)" on the page$/ do |sidebar|
  page.has_css?(sidebar)
end

Then /^I should see the "([^"]*)" within "([^"]*)"$/ do |searchbox, sidebar|
  within(sidebar) do
    page.has_css?(searchbox)
  end
end

Then /^I should see the "([^"]*)" within "([^"]*)" having link to "([^"]*)" and "([^"]*)"$/ do |treecontrol, sidebar, expandall, collapseall|
  within(sidebar) do
    within(treecontrol) do
      page.has_link?("a.#{expandall}",:href=>"#")
      page.has_link?("a.#{collapseall}",:href=>"#")
    end
  end
end

Then /^I should see the "([^"]*)" within "([^"]*)" to browse products category\-wise$/ do |browse, sidebar|
  within(sidebar) do
    page.has_css?(browse)
  end
end

Then /^I should see the link "([^"]*)" within "([^"]*)"$/ do | link, selector|
  within(selector) do
    case link
      when link == "Product A-Z"
        page.has_link?(link,:href=>"/products/a_z_products")
      else
        false
    end
  end
end

When /^I click on "([^"]*)" link within "([^"]*)"$/ do |link,selector|
  within(selector) do
    within("a.#{link}") do
      find("img.pngFix").click
    end
  end
end

Then /^I should see all the products within "([^"]*)"$/ do |browse|
  within(browse) do
    page.has_css?("li.root treeview collapsable")

  end
end

Then /^I should only see the categories within "([^"]*)"$/ do |browse|
  within(browse) do
    page.has_css?("li.root .treeview .expandable")
  end
end
