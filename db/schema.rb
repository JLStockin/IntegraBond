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

ActiveRecord::Schema.define(:version => 20120527222456) do

  create_table "accounts", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.float    "available_funds"
    t.float    "total_funds"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "accounts", ["user_id"], :name => "index_accounts_on_user_id"

  create_table "clause_roles", :force => true do |t|
    t.integer  "clause_id"
    t.integer  "role_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "clause_roles", ["clause_id"], :name => "index_clause_roles_on_clause_id"
  add_index "clause_roles", ["role_id"], :name => "index_clause_roles_on_role_id"

  create_table "clause_xassets", :force => true do |t|
    t.integer  "clause_id"
    t.integer  "xasset_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "clause_xassets", ["clause_id"], :name => "index_clause_xassets_on_clause_id"
  add_index "clause_xassets", ["xasset_id"], :name => "index_clause_xassets_on_xasset_id"

  create_table "clauses", :force => true do |t|
    t.string   "name"
    t.integer  "author_id"
    t.string   "ruby_module"
    t.string   "relative_milestones"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "contract_clauses", :force => true do |t|
    t.integer  "contract_id"
    t.integer  "clause_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "contract_clauses", ["clause_id"], :name => "index_contract_clauses_on_clause_id"
  add_index "contract_clauses", ["contract_id"], :name => "index_contract_clauses_on_contract_id"

  create_table "contracts", :force => true do |t|
    t.string   "name"
    t.integer  "author_id"
    t.string   "summary"
    t.string   "tags"
    t.string   "ruby_module"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "evidences", :force => true do |t|
    t.string   "evidence_type"
    t.string   "source"
    t.string   "description"
    t.integer  "obligation_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "evidences", ["obligation_id"], :name => "index_evidences_on_obligation_id"

  create_table "obligation_parties", :force => true do |t|
    t.integer  "obligation_id"
    t.integer  "party_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "obligation_parties", ["obligation_id"], :name => "index_obligation_parties_on_obligation_id"
  add_index "obligation_parties", ["party_id"], :name => "index_obligation_parties_on_party_id"

  create_table "obligation_valuables", :force => true do |t|
    t.integer  "obligation_id"
    t.integer  "valuable_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "obligation_valuables", ["obligation_id"], :name => "index_obligation_valuables_on_obligation_id"
  add_index "obligation_valuables", ["valuable_id"], :name => "index_obligation_valuables_on_valuable_id"

  create_table "obligations", :force => true do |t|
    t.integer  "transaction_id"
    t.integer  "clause_id"
    t.string   "state"
    t.string   "milestones"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "obligations", ["transaction_id"], :name => "index_obligations_on_transaction_id"

  create_table "parties", :force => true do |t|
    t.integer  "transaction_id"
    t.integer  "role_id"
    t.integer  "user_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "parties", ["transaction_id"], :name => "index_parties_on_transaction_id"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "transactions", :force => true do |t|
    t.integer  "contract_id"
    t.integer  "prior_transaction_id"
    t.integer  "party_of_origin_id"
    t.string   "status"
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
    t.string   "description"
    t.string   "more_description"
    t.integer  "xasset_id"
    t.integer  "transaction_id"
    t.integer  "grantee"
    t.integer  "grantor"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "xassets", :force => true do |t|
    t.string   "name"
    t.string   "asset_type"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
