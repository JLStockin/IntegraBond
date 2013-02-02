#######################################################################################
#
# Xaction -- banking-level transactions.  Adds logging and security/insulation to Account.
#
#######################################################################################

class Xaction < ActiveRecord::Base

	# Second field is number of Party(s) involved
	TRANSACTION_ACCOUNT_OPS = {\
		reserve:		["FUNDS RESERVE",	1],
		clear:			["FUNDS RELEASE",	1],
		deposit:		["DEPOSIT",			1],
		transfer:		["TRANSFER",		2],
		withdraw:		["WITHDRAW",		1] \
	}

	attr_accessible :op
	monetize :amount_cents
	monetize :hold_cents

	belongs_to :primary, class_name: Account
	belongs_to :beneficiary, class_name: Account

	validates :op, :inclusion => TRANSACTION_ACCOUNT_OPS.keys
	validates :primary, :presence => true
	validates :amount_cents, :numericality => { :greater_than => 0 } 
	validates :hold_cents, :numericality => { :greater_than_or_equal => 0 } 

	#
	# Is this a credit (true) or debit (false) to the supplied Account?
	#
	def credit_for?(account)
		if self.op.to_sym == :clear or self.op.to_sym == :deposit then 
			return true 
		elsif self.op.to_sym == :withdraw or self.op.to_sym == :reserve then
			return false 
		elsif self.op.to_sym == :transfer then 
			return (self.beneficiary_id == account.id)
		end
	end

	def amount 
		Money.new(amount_cents, currency)
	end

	def amount=(value)
		value = Money.parse(value) if value.instance_of?(String)
		write_attribute(:amount_cents, value.cents)
		write_attribute(:currency, value.currency_as_string)
	end

	def hold
		Money.new(hold_cents, currency)
	end

	def hold=(value)
		value = Money.parse(value) if value.instance_of?(String)
		write_attribute(:hold_cents, value.cents)
		write_attribute(:currency, value.currency_as_string)
	end

	# Validates existence (or absence) of second account in xaction
	def self.params_checked?(xaction, need)
		if need then
			raise "please specify second account for op '#{xaction.op}'" \
				if xaction.beneficiary.nil?
		else
			raise "second account specified for op '#{xaction.op}' not needed" \
				unless xaction.beneficiary.nil?
		end
		return true
	end

end
