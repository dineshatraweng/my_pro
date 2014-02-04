# encoding: UTF-8
class Group < ActiveRecord::Base
  has_ancestry

#  belongs_to  :parent_group
  has_many    :group_products, :dependent => :destroy
  has_many    :products, :through => :group_products
  has_many    :public_products, :through => :group_products, :class_name => "Product", :conditions => {:public => true, :visible => true}
  has_many    :employee_products, :through => :group_products, :class_name => "Product", :conditions => {:visible => true}

  accepts_nested_attributes_for :products
  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}

  before_create :save_ancestry

  def name_filter
    name_string = name
    name_string.gsub("®".force_encoding('utf-8'),"<sup>®</sup>").gsub("&reg;","<sup>®</sup>").gsub("&REG;","<sup>®</sup>").gsub('&reg',"&amp;reg").gsub('&REG',"&amp;REG").html_safe
  end

  def self.groups_breadcrumb
    arr = []
    all_groups = self.all(:order => 'ancestry')

    all_groups.each do |g|
      label = []
      Group.ancestors_of(g).each do |ancestor|
        label << ancestor.name.gsub("®".force_encoding('utf-8'),"<sup>®</sup>").gsub('&reg;',"<sup>®</sup>").gsub("&REG;","<sup>®</sup>").gsub('&reg',"&amp;reg").gsub('&REG',"&amp;REG").html_safe
      end
      label << g.name.gsub("®".force_encoding('utf-8'),"<sup>®</sup>").gsub('&reg;',"<sup>®</sup>").gsub("&REG;","<sup>®</sup>").gsub('&reg',"&amp;reg").gsub('&REG',"&amp;REG").html_safe
      arr << [label.join(" > ").html_safe,g.id]
    end

    return arr
  end

  def save_ancestry
    unless self.parent_group_id.blank?
      parent_group = self.class.find(self.parent_group_id)
      self.ancestry = (parent_group.ancestry.blank? ? "#{parent_group.id}" : "#{parent_group.ancestry}/#{parent_group.id}")
    end
  end

  def update_child_groups_ancestry
    ancestry = self.ancestry.blank? ? "#{self.id}" : "#{self.ancestry}/#{self.id}"
    self.children.each{ |c| c.update_attributes(:ancestry => ancestry) } if self.has_children?
  end

  def move_group_products_to_parent_group
    if self.is_root?
      self.children.each {|child| child.destroy}
    else
      parent = self.parent

      self.products.each do |p|
        group_prod = parent.group_products.build(:product_id => p.id)
        group_prod.save
      end

      self.children.each do |child|
        ancestry = child.ancestry.split("/")
        ancestry.pop
        child.update_attributes(:ancestry => ancestry.join("/"))
      end
      
    end
  end

  def all_products_in_hierarchy
    arr=[]
    arr << self.products.order('name') unless self.products.blank?
    self.children.each do |child|
      all_prods = child.all_products_in_hierarchy
      arr << all_prods unless all_prods.blank?
    end
    new_arr=[]
    arr.each do |t|
      t.each{|dt| new_arr << dt}
    end
    return new_arr
  end
  
end