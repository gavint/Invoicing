# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_01_000004) do
  create_table "contacts", force: :cascade do |t|
    t.string "billing_address_line1"
    t.string "billing_address_line2"
    t.string "billing_city"
    t.string "billing_country"
    t.string "billing_state"
    t.string "billing_zip"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "invoice_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "invoice_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0"
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "invoice_number", null: false
    t.date "issue_date"
    t.text "notes"
    t.datetime "paid_at"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_invoices_on_contact_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.string "company_address_line1"
    t.string "company_address_line2"
    t.string "company_city"
    t.string "company_country"
    t.string "company_email"
    t.string "company_name"
    t.string "company_phone"
    t.string "company_state"
    t.string "company_zip"
    t.datetime "created_at", null: false
    t.text "invoice_footer_note"
    t.string "smtp_address"
    t.string "smtp_password"
    t.integer "smtp_port"
    t.string "smtp_username"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "contacts"
end
