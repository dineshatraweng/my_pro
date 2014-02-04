# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140102070016) do

  create_table "audits", :force => true do |t|
    t.integer  "payload_id"
    t.string   "payload_type"
    t.integer  "user_id"
    t.text     "payload_json"
    t.text     "modified_attributes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "content"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ancestry"
  end

  add_index "comments", ["ancestry"], :name => "index_comments_on_ancestry"

  create_table "doc_ftps", :force => true do |t|
    t.string   "name"
    t.text     "path"
    t.string   "doctype",       :default => "FOLDER_PATH"
    t.string   "status",        :default => "ZIPPED"
    t.text     "error_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "doc_types", :force => true do |t|
    t.string   "doctype"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "document_doc_types", :force => true do |t|
    t.integer  "document_id"
    t.integer  "doc_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "link"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "doc_type_id"
    t.integer  "document_order"
    t.integer  "pdf_count"
    t.datetime "out_of_cycle"
    t.string   "doctype",        :default => "FOLDER_PATH"
  end

  create_table "friendly_id_slugs", :force => true do |t|
    t.string   "slug",                         :null => false
    t.integer  "sluggable_id",                 :null => false
    t.string   "sluggable_type", :limit => 40
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type"], :name => "index_friendly_id_slugs_on_slug_and_sluggable_type", :unique => true
  add_index "friendly_id_slugs", ["sluggable_id"], :name => "index_friendly_id_slugs_on_sluggable_id"
  add_index "friendly_id_slugs", ["sluggable_type"], :name => "index_friendly_id_slugs_on_sluggable_type"

  create_table "group_products", :force => true do |t|
    t.integer  "group_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "parent_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ancestry"
  end

  add_index "groups", ["ancestry"], :name => "index_groups_on_ancestry"

  create_table "parent_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "folder_path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "doctype"
    t.boolean  "public",         :default => false
    t.boolean  "visible",        :default => true
    t.string   "filtered_name"
    t.string   "slug"
    t.boolean  "oem",            :default => false
    t.string   "ancestry"
    t.boolean  "versioned"
    t.string   "version_no"
    t.integer  "order"
    t.boolean  "default",        :default => false
    t.string   "subject_name"
    t.text     "tags"
    t.boolean  "published",      :default => true
    t.datetime "published_date", :default => '2014-01-25 12:22:33'
  end

  add_index "products", ["ancestry"], :name => "index_products_on_ancestry"
  add_index "products", ["slug"], :name => "index_products_on_slug"

  create_table "ratings", :force => true do |t|
    t.float    "rating"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "email"
    t.string   "firstname"
    t.string   "lastname"
    t.string   "type",              :default => "Admin"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_request_at"
    t.string   "current_login_ip"
  end

  create_table "versions", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "version_number"
    t.text     "folder_path"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
