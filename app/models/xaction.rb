#######################################################################################
#
# Xaction -- banking-level transactions.  Adds logging and security/insulation to Account.
# The changes to the Account(s) occur as the Xaction is saved. 
# Note that bonds may be asymmetric; therefore, Xaction only releases funds for the
# benefactor.  NB: the params_checked has to be released in another Xaction.
#
#######################################################################################

#
# All the action happens in this Xaction#before_save() callback.
#
class XactionCallback

	def self.before_save(xaction)
		result = false
		if xaction.valid? and xaction.primary.valid? then

			if (xaction.op == :reserve) then
				result = params_checked?(xaction, false) \
					and xaction.primary.reserve(xaction.amount) \
					and xaction.primary.save!

			elsif (xaction.op == :release) then
				result = params_checked?(xaction, false) \
					and xaction.primary.clear(xaction.amount) \
					and xaction.primary.save!

			elsif (xaction.op == :transfer) then
				result = params_checked?(xaction, true) \
					and Account.transfer(xaction.amount, xaction.primary, \
						xaction.beneficiary, xaction.hold.nil? ? Money.new(0) : xaction.hold) \
					and xaction.primary.save! \
					and xaction.beneficiary.save!

			elsif (xaction.op == :deposit) then
				result = params_checked?(xaction, false) \
					and xaction.primary.deposit(xaction.amount, \
						xaction.hold.nil? ? Money.new(0) : xaction.hold) \
					and xaction.primary.save!

			elsif (xaction.op == :withdraw) then
				result = params_checked?(xaction, false) \
					and xaction.primary.withdraw(xaction.amount) \
					and xaction.primary.save!

			else
				raise "unsupported op '#{op}'"
			end
		else
			return false
		end
		result
	end

	# Validates existence (or absence) of params_checked in xaction
	def self.params_checked?(xaction, need)
		if need then
			raise "please specify second account for op '#{xaction.other_account}'" \
				if xaction.beneficiary.nil?
		else
			raise "second account specified for op '#{xaction.other_account}' not needed" \
				unless xaction.beneficiary.nil?
		end
		return true
	end
end

class Xaction < ActiveRecord::Base

	# Second field is number of Party(s) involved
	TRANSACTION_ACCOUNT_OPS = {\
		reserve:		["FUNDS RESERVE",	1],
		release:		["FUNDS RELEASE",	1],
		deposit:		["DEPOSIT",			1],
		transfer:		["TRANSFER",		2],
		withdraw:		["WITHDRAW",		1] \
	}

	attr_accessible :op
	monetize :amount_cents
	monetize :hold_cents

	belongs_to :primary, class_name: Account, foreign_key: :primary_id
	belongs_to :beneficiary, class_name: Account, foreign_key: :beneficiary_id

	validates :op, :inclusion => TRANSACTION_ACCOUNT_OPS.keys
	validates :primary, :presence => true
	validates :amount_cents, :numericality => { :greater_than => 0 } 
	validates :hold_cents, :numericality => { :greater_than_or_equal => 0 } 

	before_save	XactionCallback 

	#
	# Is this a credit (true) or debit (false) to the supplied Account?
	#
	def credit_for?(account)
		if self.op.to_sym == :release or self.op.to_sym == :deposit then 
			return true 
		elsif self.op.to_sym == :withdraw or self.op.to_sym == :reserve then
			return false 
		elsif self.op.to_sym == :transfer then 
			return (self.beneficiary_id == account.id)
		end
	end
end
