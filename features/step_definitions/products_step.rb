def create_product
  @group1 = FactoryGirl.create(:group, :name=>"category_1")
  @current_product = Factory(:product ,:name=> "tibco",:visible=>true ,:public=> true)
  #@current_product2 = FactoryGirl.create(:product ,:name=> "prod2",:visible=>false ,:public=> false)
end

def create_public_product
  @pub_product = Factory(:product ,:name=> "public_prod",:visible=>true ,:public=> true)
end

def create_require_login_product
  @req_login_product = Factory(:product ,:name=> "require_login_prod",:visible=>true ,:public=> false)
end

def create_admin_product
  @admin_product = Factory(:product ,:name=> "admin_prod",:visible=>false ,:public=> false)
end

def create_categories
  @categories = Factory(:group, :name=>"category_1")
end

def create_products
  @products = FactoryGirl.create_list(:product,5)
  create_public_product
end

#@product_az------------------------------------------------------------------------------------------------------------
Given /^I have some products$/ do
  create_products
end

When /^I click on "([^"]*)" link$/ do |link|
  case link
    when "product"
      within("#content-wrapper #content #side-bar ul li span.expandable-level-1") do
        click_link "admin_prod" rescue click_link "require_login_prod" rescue click_link "public_prod"
      end
    else
      within("#content-wrapper #content #side-bar ul li span.expandable-level-0") do
        click_link link
      end
  end
end

#@product_az
Then /^I should see the A\-Z Product listing$/ do
  current_path.should == a_z_products_products_path
  page.has_css?("#az-wrap")
end

#@product_az
When /^I select one of product$/ do
  within("#az-wrap") do
    page.has_css?("ul.products-for-group")
    click_link("public_prod")
  end
  #print page.html
end

#@product_az
Then /^I should see the "([^"]*)" page$/ do |arg1|
  page.has_content?("public_prod")
end

Given /^I have "([^"]*)" products$/ do |type|
  send("create_#{type}_product")
end

When /^I login as "([^"]*)"$/ do |user|
  admin_user if user == "admin"
  send("#{user}_login")
end

Then /^I should see "([^"]*)" on the current page$/ do |element|
  page.has_css?(element)
end

Then /^I should see "([^"]*)" products$/ do |type|
  page.has_content?("#{type}_prod")
  page.has_css?(".pngFix secure-folder")
  page.has_css?(".folder pngFix")
end

Then /^As a "([^"]*)" I should see the "([^"]*)" product page$/ do |user,type|
  #print page.html
  within("#main-content") do
    within("#breadcrumb") do
      page.has_content?("category_")
    end
    within("#heading-wrap") do
      page.has_content?("public_prod") if type == "public"
      page.has_content?("require_login_prod") if type == "require_login"
      page.has_content?("admin_prod") if type == "admin"
    end
    within("#rating") do
      page.has_content?("Rate the documentation:")
      within("#rating-star") do
        (1..5).each {|i| page.has_css?("#rating-star-#{i}",:src=>"/images/star-off.png"); print "star #{i}"}
      end
    end
    page.has_css?("efwefwefget-feedback")
    page.has_content?("Send feedback on documentation")
    print page.html
    if user == "admin"
      page.has_content?("Requires Login") if type == "require_login"
      page.has_content?("Admins Only") if type == "admin"
      page.has_content?("Open to the Public") if type == "public"
      page.has_link?("edit")
      page.has_link?("delete")
      page.has_link?("ofc")
    end
  end
end

