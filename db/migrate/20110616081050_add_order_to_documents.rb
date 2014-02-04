class AddOrderToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :document_order, :integer

    products = Product.all
    products.each do |p|
      p.documents.each_with_index do |doc,index|
        doc.update_attributes(:document_order => (index+1))
      end
    end

  end

  def self.down
    remove_column :documents, :document_order
  end
end
