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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180119161214) do

  create_table "categories", force: :cascade do |t|
    t.integer "product_id", limit: 10, precision: 10
    t.string "category_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id", limit: 10, precision: 10
    t.boolean "private"
    t.index ["product_id"], name: "index_categories_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "product_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "queue_managers", force: :cascade do |t|
    t.string "manager_name"
    t.string "queue_out"
    t.string "host"
    t.string "port"
    t.string "user"
    t.string "password"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "manager_type"
    t.string "amq_protocol"
    t.string "channel_manager"
    t.string "channel"
    t.string "queue_in"
    t.integer "user_id", limit: 10, precision: 10
    t.boolean "visible_all", default: false
  end

  create_table "simple_tests", force: :cascade do |t|
    t.integer "xml_id", limit: 10, precision: 10
    t.integer "queue_manager_id", limit: 10, precision: 10
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["xml_id"], name: "index_simple_tests_on_xml_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "xmls", force: :cascade do |t|
    t.string "xml_name"
    t.text "xml_text"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "category_id", limit: 10, precision: 10
    t.integer "user_id", limit: 10, precision: 10
    t.boolean "private"
    t.text "xml_description"
    t.index ["category_id"], name: "index_xmls_on_category_id"
  end

end
