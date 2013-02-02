MZERO = Money.new(0)
PARAM_ERROR = "improper params"

class InsufficientFundsError < RuntimeError
end

class Account < ActiveRecord::Base
  
	attr_accessible		:name

	belongs_to :user, inverse_of: :account

	has_many :primaries, class_name: Xaction, foreign_key: :primary_id, dependent: :destroy
	has_many :beneficiaries, class_name: Xaction, foreign_key: :beneficiary_id, dependent: :destroy

	#attr_accessor :funds_cents, :hold_funds_cents
	monetize	:funds_cents, :hold_funds_cents

	#######################################################################
	#
	# Instance initialization, validation
	#

	# Populate fields with defaults for new records
	class AccountInitializer
		def self.before_create(record)
			record.funds_cents ||= 0 
			record.hold_funds_cents ||= 0 
			record.currency ||= "USD" 
		end
	end

	before_create		AccountInitializer

	class AccountValidator < ActiveModel::Validator

		def validate(record)
			if (record.hold_funds_cents > record.funds_cents) then
				record.errors[:base] << "Available funds #{record.available_funds} " + \
					"can't exceed total funds (#{record.total_funds})"
			elsif (record.funds_cents < 0) then
				record.errors[:base] << "Funds #{record.funds} " + \
					"can't be less than zero"
			elsif (record.hold_funds_cents < 0) then
				record.errors[:base] << "total funds #{record.funds} " + \
					"can't be less than zero"
			end
		end
	end

	validates_with		AccountValidator

	#######################################################################

	def sufficient_funds?(amnt)
		Money.parse(amnt) <= available_funds()
	end

	def available_funds()
		return self.funds - self.hold_funds
	end

	def total_funds()
		return self.funds
	end

	def reserve(amnt, debug = false)
		Account.transaction do
			amnt = Money.parse(amnt) 
			xaction = Xaction.new(op: :reserve)
			xaction.primary = self 
			xaction.beneficiary = nil 
			xaction.amount = amnt 
			xaction.hold = MZERO 
			raise PARAM_ERROR unless Xaction.params_checked?(xaction, false)

			self.reload
			raise ArgumentError.new("can't reserve zero or negative amount.") if amnt <= 0
			raise InsufficientFundsError.new("insufficient funds") unless sufficient_funds?(amnt)
			self.hold_funds += amnt
			xaction.save!
			save!

		end
	end

	def clear(amnt)
		Account.transaction do
			amnt = Money.parse(amnt) 	
			xaction = Xaction.new(op: :clear)
			xaction.amount = amnt 
			xaction.hold =  MZERO
			xaction.primary = self 
			raise PARAM_ERROR unless Xaction.params_checked?(xaction, false)

			self.reload
			raise ArgumentError.new("can't clear negative funds or more than is in account.") \
				if amnt <= 0 or amnt > self.hold_funds
			self.hold_funds -= amnt 
			xaction.save!
			self.save!
		end
	end

	def deposit(amnt, amnt_to_reserve)
		Account.transaction do
			amnt = Money.parse(amnt)
			amnt_to_reserve = Money.parse(amnt_to_reserve)
			xaction = Xaction.new(op: :deposit)
			xaction.amount = amnt
			xaction.hold = amnt_to_reserve 
			xaction.primary = self
			raise PARAM_ERROR unless Xaction.params_checked?(xaction, false)

			self.reload
			raise ArgumentError.new("can't clear #{amnt_to_reserve} for #{amnt}") \
				if amnt <= 0 or amnt_to_reserve < 0 or amnt_to_reserve > amnt
			self.funds += amnt
			self.hold_funds += amnt_to_reserve if amnt_to_reserve >= MZERO
			xaction.save!
			save!
		end
	end

	def withdraw(amnt)
		Account.transaction do
			amnt = Money.parse(amnt)  
			xaction = Xaction.new(op: :withdraw)
			xaction.amount = amnt
			xaction.hold = MZERO 
			xaction.primary = self
			raise PARAM_ERROR unless Xaction.params_checked?(xaction, false)

			self.reload
			raise ArgumentError.new("can't withdraw zero or negative funds amount.") if amnt <= 0
			raise InsufficientFundsError.new(
				"#{amnt} will overdraft account (available funds = #{available_funds})."
			) if !sufficient_funds?(amnt)
			self.funds -= amnt 
			xaction.save!
			save!
		end
	end

	def Account.transfer(amnt, from, to, clear_amnt="$0")
		Account.transaction do
			amnt = Money.parse(amnt) 
			clear_amnt = Money.parse(clear_amnt)
			xaction = Xaction.new(op: :transfer)
			xaction.amount = amnt 
			xaction.hold = clear_amnt 
			xaction.primary = from 
			xaction.beneficiary = to 
			raise PARAM_ERROR unless Xaction.params_checked?(xaction, true)

			from.reload
			to.reload
			raise ArgumentError.new("can't withdraw zero or negative funds amount.") \
				if (amnt <= MZERO or clear_amnt < MZERO \
					or !from.sufficient_funds?(amnt - clear_amnt))

			from.hold_funds -= clear_amnt if clear_amnt > MZERO 
			from.funds -= amnt
			to.funds += amnt

			xaction.save!
			from.save!
			to.save!
		end
	end
		
	def to_s
		"#{funds}, #{hold_funds}(h)"
	end

	if Rails.env.test? or Rails.env.development?
		def set_funds(amnt, reserve)
			self.reload
			amnt = Money.parse(amnt) 
			self.funds = amnt 
			reserve = Money.parse(reserve)
			self.hold_funds = reserve
			save!
		end

	end

	#######################################################################
	#
	# Methods that should be part of the money_rails gem.
	# Note that they share the single currency field in the DB table.
	#

	def funds
		Money.new(funds_cents, currency)
	end

	def funds=(value)
		value = Money.parse(value) if value.instance_of?(String)
		write_attribute(:funds_cents, value.cents)
		write_attribute(:currency, value.currency_as_string)
	end

	def hold_funds
		Money.new(hold_funds_cents, currency)
	end

	def hold_funds=(value)
		value = Money.parse(value) if value.instance_of?(String)
		write_attribute(:hold_funds_cents, value.cents)
		write_attribute(:currency, value.currency_as_string)
	end

end
