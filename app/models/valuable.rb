class Valuable < ActiveRecord::Base
  attr_accessible :xasset_id, :description, :more_description, :transaction_id, :user_who_know_holds_id, :user_who_owns_id, :user_who_will_own_id
end
