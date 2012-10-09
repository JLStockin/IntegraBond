MZERO = Money.new(0)

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

class Account < ActiveRecord::Base
  
	attr_accessible		:name

	belongs_to :user
	validates_with		::AccountValidator

	def sufficient_funds?(amnt)
		Money.parse(amnt) <= available_funds()
	end

	def available_funds()
		return self.funds - self.hold_funds
	end

	def total_funds()
		return self.funds
	end

	def reserve(amnt)
		amnt = Money.parse(amnt) 
		raise "can't reserve zero or negative amount." if amnt <= 0
		raise "insufficient funds" if !sufficient_funds?(amnt) 
		self.hold_funds += amnt
	end

	def clear(amnt)
		amnt = Money.parse(amnt) 	
		raise "can't clear negative funds or more than is in account." \
			if amnt <= 0 or amnt > self.hold_funds
		self.hold_funds -= amnt 
	end

	def deposit(amnt, amnt_to_reserve)
		amnt = Money.parse(amnt)
		amnt_to_reserve = Money.parse(amnt_to_reserve)
		raise "can't clear #{amnt_to_reserve} for #{amnt}" \
			if amnt <= 0 or amnt_to_reserve < 0 or amnt_to_reserve > amnt
		self.funds += amnt
		self.hold_funds += amnt_to_reserve if amnt_to_reserve >= MZERO
	end

	def withdraw(amnt)
		amnt = Money.parse(amnt)  
		raise "can't withdraw zero or negative funds amount." if amnt <= 0
		raise "#{amnt} will overdraft account (available funds = #{available_funds})." \
			if !sufficient_funds?(amnt)
		self.funds -= amnt 
	end

	def Account.transfer(amnt, from, to, clear_amnt=0)
		amnt = Money.parse(amnt) 
		clear_amnt = Money.parse(clear_amnt)
		raise "can't withdraw zero or negative funds amount." \
			if (amnt <= MZERO or clear_amnt < MZERO \
				or !from.sufficient_funds?(amnt - clear_amnt))
		from.clear(clear_amnt) if clear_amnt > MZERO 
		from.withdraw(amnt)
		to.deposit(amnt, 0)
	end
		
	def to_s
		"#{funds}, #{hold_funds}(h)"
	end

	if Rails.env.test? or Rails.env.development?
		def set_funds(amnt, reserve)
			amnt = Money.parse(amnt) 
			self.funds = amnt 
			reserve = Money.parse(reserve)
			self.hold_funds = reserve
		end

	end


	#
	# These are needed to make Money compatible with ActiveRecord
	#
	def funds
		write_attribute(:funds_cents, 0) if read_attribute(:funds_cents).nil?
		write_attribute(:funds_currency, Money.default_currency) \
			if read_attribute(:funds_currency).nil?
		Money.new(read_attribute(:funds_cents), read_attribute(:funds_currency))
	end

	def hold_funds
		write_attribute(:hold_funds_cents, 0) if read_attribute(:hold_funds_cents).nil?
		write_attribute(:funds_currency, Money.default_currency) \
			if read_attribute(:funds_currency).nil?
		Money.new(read_attribute(:hold_funds_cents), read_attribute(:funds_currency))
	end

	def funds=(value)
		Money.parse(value).tap do |fnds|
			write_attribute :funds_cents, fnds.cents
			write_attribute :funds_currency, fnds.currency_as_string
		end
	end

	def hold_funds=(value)
		Money.parse(value).tap do |fnds|
			write_attribute :hold_funds_cents, fnds.cents
			write_attribute :funds_currency, fnds.currency_as_string
		end
	end

end
