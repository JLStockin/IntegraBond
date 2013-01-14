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

ActiveRecord::Schema.define(:version => 20121114190401) do

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

  create_table "artifacts", :force => true do |t|
    t.string   "type"
    t.integer  "tranzaction_id"
    t.integer  "goal_id"
    t.text     "_ar_data"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "artifacts", ["tranzaction_id"], :name => "index_artifacts_on_tranzaction_id"

  create_table "contacts", :force => true do |t|
    t.string   "type"
    t.string   "contact_data"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "contacts", ["contact_data"], :name => "index_contacts_on_contact_data"

  create_table "expirations", :force => true do |t|
    t.string   "type"
    t.integer  "tranzaction_id"
    t.integer  "goal_id"
    t.integer  "offset"
    t.string   "offset_units"
    t.datetime "value"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "expirations", ["value"], :name => "index_expirations_on_value"

  create_table "goals", :force => true do |t|
    t.string   "type"
    t.integer  "tranzaction_id"
    t.string   "machine_state"
    t.text     "_ar_data"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "goals", ["tranzaction_id"], :name => "index_goals_on_tranzaction_id"

  create_table "invitations", :force => true do |t|
    t.string   "type"
    t.integer  "party_id"
    t.string   "slug"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "invitations", ["party_id"], :name => "index_invitations_on_party_id"
  add_index "invitations", ["slug"], :name => "index_invitations_on_slug"

  create_table "parties", :force => true do |t|
    t.string   "type"
    t.integer  "contact_id"
    t.integer  "tranzaction_id"
    t.string   "contact_strategy"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "parties", ["contact_id"], :name => "index_parties_on_contact_id"
  add_index "parties", ["tranzaction_id"], :name => "index_parties_on_tranzaction_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tranzactions", :force => true do |t|
    t.string   "type"
    t.integer  "originator_id"
    t.text     "_ar_data"
    t.string   "wizard_step"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "first_name"
    t.string   "last_name"
    t.text     "_ar_data"
    t.string   "encrypted_password"
    t.string   "salt"
    t.boolean  "admin",              :default => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "valuables", :force => true do |t|
    t.string   "type"
    t.integer  "tranzaction_id"
    t.string   "machine_state"
    t.integer  "value_cents"
    t.integer  "origin_id"
    t.integer  "disposition_id"
    t.text     "_ar_data"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "xactions", :force => true do |t|
    t.string   "op"
    t.integer  "primary_id"
    t.integer  "beneficiary_id"
    t.integer  "amount_cents"
    t.integer  "hold_cents"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "xactions", ["beneficiary_id"], :name => "index_xactions_on_beneficiary_id"
  add_index "xactions", ["primary_id"], :name => "index_xactions_on_primary_id"

end
