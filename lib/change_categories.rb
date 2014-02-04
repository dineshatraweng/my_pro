#encoding: utf-8
module ChangeCategories
  require "#{Rails.root}/lib/category_products.rb"
  CATEGORY_PRODUCTS = CategoryProducts::CATEGORY_PRODUCTS

  #-------------------------------------------        Methods         --------------------------------------------------

  def self.new_categories
    return {'Automation'       => {'Application Integration'    => [{'Business to Business (B2B)'   => ['BusinessConnect', 'Foresight']},
                                                                    {'Enterprise Service Bus (ESB)' => ['TIBCO Adapter™ Software']},
                                                                    'Mainframe Integration',
                                                                    'Managed File Transfer (MFT)',
                                                                    'Pattern Matching',
                                                                    'TIBCO ActiveMatrix BusinessWorks™'] ,
                                   'Application Development'    => ['Grid Computing',
                                                                    'Mobile Application Development',
                                                                    {'SOA Development' => ['TIBCO ActiveMatrix BusinessWorks',
                                                                                           'TIBCO ActiveMatrix® Adapter Service Engine Software',
                                                                                           'TIBCO ActiveMatrix® Adapter Software']},
                                                                    'SOA Governance'],
                                   #'API Management'             => API_MGMT_SUB_CATEGORIES,       ##No Product present under API Management > API_MGMT_SUB_CATEGORIES
                                   'Business Process Management (BPM)' =>[{'Business Process Improvement' => 'TIBCO iProcess® Suite'},
                                                                          'Process and Workforce Automation',
                                                                          'Simple Apps, Forms, and Flows'],
                                   'In-Memory Computing'        => ['In-Memory Data Grid',
                                                                    'Transactional Application Server'],
                                   'Messaging'                  => [ 'Enterprise Messaging', 'High-Performance Messaging'],
                                   'Master Data Management'     => [ 'MDM' ],
                                   'Monitoring & Management'    => ['Enterprise Monitoring',
                                                                    'SLA & Business Metrics',
                                                                    'TIBCO Infrastructure']
    },
            'Event Processing' => ['Complex Event Processing(CEP)',
                                   'Log Management'],
            'Analytics'        => ['Analytics & Visualization'],
            #'Cloud'            => CLOUD_CATEGORIES,     ##No Product present under cloud CATEGORIES
            'Social'           => ['Social Collaboration',
                                   'Social BPM']
    }
  end



  def self.find_or_create_category_name(category_name)
    Group.find_by_name(category_name)
  end

  def self.create_category(options)
    group = Group.new(options)
    if group.save
      print_messages("Category '#{group.name}' created successfully")
      group
    else
      print_messages("Error in creating category with name '#{group.name}' => #{group.errors.full_messages}")
      find_category(options)
    end
  end

  def self.find_category(options)
    if name.blank?
      print_messages "No valid name give to find_category"
    else
      groups = Group.find_all_by_name(options[:name])
      unless groups.blank?
        print_messages("Cannot create category because category with '#{options[:name]}' already exists")
        print_messages("Updating previous category and creating new one")
        groups.each {|group| group.update_attributes(:name => group.name + " Category")}
        group = Group.new(options)
        if group.save
          print_messages("Category '#{group.name}' created successfully")
          group
        else
          print_messages("Error in creating category with name '#{group.name}' => #{group.errors.full_messages}")
        end
      end
    end
  end

  def self.print_messages(message)
    puts(message)
    Rails.logger.info(message)
  end

  def self.create_categories(categories, parent_category_id = nil)
    if categories.is_a?(Hash)
      categories.each_pair do |parent_category_name, sub_categories|
        parent_category = create_categories(parent_category_name, parent_category_id)
        if parent_category.blank?
          print_messages "Cannot create further sub categories"
        else
          create_categories(sub_categories, parent_category.id )
        end

      end
    elsif categories.is_a?(Array)
      categories.each do |category|
        create_categories(category, parent_category_id )
      end
    elsif categories.is_a?(String)
      ##create category
      category_name = categories.dup
      category = create_category(:name => category_name.force_encoding("UTF-8"), :parent_group_id => parent_category_id)
      ##add products to category if category successfully created
      add_products_to_category(category) unless category.blank?
      print_messages("-----------------------------------------------------------------------------------\n")
      return category
    else
      print_messages(categories.class)
      print_messages("Error in creating categories due to invalid data")
    end
  end

  def self.add_products_to_category(category)
    product_names = CATEGORY_PRODUCTS[category.name]
    unless product_names.blank?
      product_names_ct = product_names.size
      products = get_all_products_by_name(product_names)
      products.each do |product|
        change_product_category([product], category)
      end
      stats = category.save
      category_products = category.products.select{|p| p.is_parent_product?}
      category_products_ct = category_products.count
      if product_names_ct == category_products_ct
        print_messages("All (#{category_products_ct}) product are added to '#{category.name}'")
        print_messages("(#{category_products_ct}) Products Name to be added :\n #{product_names.inspect}\n\n ")
        print_messages("(#{category_products_ct}) Products Added : \n #{category_products.map(&:name)}")
      else
        print_messages("All (#{category_products_ct}) product are not added to '#{category.name}'. #{product_names_ct - category_products_ct} no of products not added")
      end
      return stats
    end
  end

  def self.change_product_category(products, category)
    unless products.blank?
      products.each do |product|
        product.groups = []
        product.groups = [category]
        product.save
        if product.is_parent_product?
          print_messages("changing (#{product.children.size}) product versions to '#{category.name}' category")
          change_product_category(product.children, category)
        end
      end
    end
  end


  def self.get_all_products_by_name(product_names)
    names = product_names.select{|name| name.force_encoding("UTF-8")}
    Product.find_all_by_name(names)
  end

  def self.create_new_categories
    categories = new_categories
    self.create_categories(categories)
  end


  def self.clean_last_products
    product1 = Product.find_by_slug("TIBCO StreamBase  CEP 7.3.6".gsub(/[®©™]/,"").parameterize.force_encoding("UTF-8"))
    product2 = Product.find_by_slug("TIBCO StreamBase CEP 7.3.7".gsub(/[®©™]/,"").parameterize.force_encoding("UTF-8"))
    group = Group.find_by_name("Complex Event Processing(CEP)")
    product1.groups = [group]
    product1.save
    product2.groups = [group]
    product2.save

    group1 = Group.find_by_name("Business Optimization")
    unless group.products.blank?
      print_messages("Removing products from category 'Business Optimization'")
      group1.products = []
      group1.save
    end
  end
end