FactoryGirl.define do
  factory :group do |f|
    f.sequence(:name) {|n| "category_#{n}" }
  end

  def get_group_named(name)
    # get existing group or create new one
    Group.where(:name => name).first || Factory(:group, :name => name)
  end

  factory :product do |f|
    f.sequence(:name) {|n| "tibco_#{n}" }
    f.folder_path     "TISCO"
    f.groups          {|groups| [groups.association(:group)]}
  end

  def get_product_named(name)
    # get existing product or create new one
    Product.where(:name => name).first || FactoryGirl(:product, :name => name)
  end


  factory :document do |f|
    f.sequence(:name) {|n| "docs_#{n}" }
    f.link            "Tibco_1/doc.docx  "
    f.association     :product
  end

  factory :product_with_documents, :parent => :product  do |f|
    f.sequence(:name) {|n| "tibco_#{n}" }
    f.folder_path     "TISCO"
    f.groups          {|groups| get_group_named("category_1")}
    f.after_build do |p|
      p.documents       [FactoryGirl(:document,
                                     :name => "#{f.name}_doc_1",
                                     :link => "Tibco_1/doc.docx"),
                         FactoryGirl(:document,
                                     :name => "#{f.name}_doc_2",
                                     :link => "Tibco_1/doc.docx")]
    end
  end
  factory :user do |f|
    f.username              "testadmin"
    f.email                 "test@example.com" #{|n| "#{f.username}_#{n}@raweng.com" }
    f.password              "test123"
    f.password_confirmation "test123"
    f.type                  "Admin"
  end

  #factory :watchings do |group_products|
  #   group_products.association(:group)
  #   group_products.association(:product)
  #
  #end
end

