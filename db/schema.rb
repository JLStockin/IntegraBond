# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20120810012222) do

  create_table "accounts", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.integer  "funds_cents",      :default => 0, :null => false
    t.integer  "hold_funds_cents", :default => 0, :null => false
    t.string   "funds_currency"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "accounts", ["user_id"], :name => "index_accounts_on_user_id"

  create_table "disputes", :force => true do |t|
    t.integer  "transaction_id"
    t.string   "claimant"
    t.string   "counterparty"
    t.text     "allegation"
    t.text     "response"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "disputes", ["transaction_id"], :name => "index_disputes_on_transaction_id"

  create_table "evidences", :force => true do |t|
    t.integer  "transaction_id"
    t.string   "hash"
    t.string   "description_short"
    t.string   "description_long"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "evidences", ["transaction_id"], :name => "index_evidences_on_transaction_id"

  create_table "parties", :force => true do |t|
    t.integer  "transaction_id"
    t.string   "role"
    t.integer  "user_id"
    t.boolean  "is_bonded"
    t.integer  "bound_amount"
    t.integer  "fees_amount"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "parties", ["transaction_id"], :name => "index_parties_on_transaction_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "transactions", :force => true do |t|
    t.string   "type"
    t.integer  "prior_transaction_id"
    t.string   "author_email"
    t.string   "role_of_origin"
    t.string   "milestones"
    t.string   "machine_state"
    t.string   "transaction_params"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "encrypted_password"
    t.string   "salt"
    t.boolean  "admin",              :default => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

  create_table "valuables", :force => true do |t|
    t.integer  "transaction_id"
    t.integer  "value_cents"
    t.string   "xasset"
    t.string   "description"
    t.string   "more_description"
    t.string   "assigned_to"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "xactions", :force => true do |t|
    t.string   "op"
    t.integer  "primary_id"
    t.integer  "beneficiary_id"
    t.integer  "amount_cents"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

end
