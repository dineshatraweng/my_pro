task :product_categories_migration => :environment do
  require "#{Rails.root}/lib/change_categories.rb"
  require "#{Rails.root}/lib/category_products.rb"

  ChangeCategories.print_messages("starting Process ........................................")
  ChangeCategories.create_new_categories
  ChangeCategories.print_messages("moving TIBCO StreamBase  CEP 7.3.6 and TIBCO StreamBase CEP 7.3.7 to catgory Complex Event Processing(CEP)")
  ChangeCategories.clean_last_products
  ChangeCategories.print_messages("Moved!!")
  ChangeCategories.print_messages("........................................Process completed")

end