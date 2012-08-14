#######################################################################################
#
# Xaction -- banking-level transactions.  Adds logging and security/insulation to Account.
# The changes to the Account(s) occur as the Xaction is saved. 
# Note that bonds may be asymmetric; therefore, Xaction only releases funds for the
# benefactor.  NB: the beneficiary has to be released in another Xaction.
#
#######################################################################################

#
# All the action happens in this Xaction#before_save() callback.
#
class XactionCallback

	def before_save(xaction)
		result = false
		if xaction.valid? and xaction.primary.account.valid? then

			if (xaction.op == :reserve) then
				result = beneficiary?(xaction, false) \
					and xaction.primary.account.reserve_funds(xaction.amount) \
					and xaction.primary.account.save!

			elsif (xaction.op == :release) then
				result = beneficiary?(xaction, false) \
					and xaction.primary.account.clear_funds(xaction.amount) \
					and xaction.primary.account.save!

			elsif (xaction.op == :credit) then
				result = beneficiary?(xaction, true) \
					and Xaction.transfer(xaction.amount, admin_account(), \
						xaction.beneficiary.account, 0)

			elsif (xaction.op == :bond_transfer) then
				result = beneficiary?(xaction, true) \
					and Account.transfer(xaction.amount, xaction.primary.account, \
						xaction.beneficiary.account, xaction.amount)

			elsif (xaction.op == :fee_change) then
				result = beneficiary?(xaction, true) \
					and Account.transfer(xaction.amount, xaction.primary.account, \
						xaction.beneficiary.account, xaction.amount)

			elsif (xaction.op == :deposit) then
				result = beneficiary?(xaction, false) \
					and xaction.primary.account.deposit(xaction.amount) \
					and xaction.primary.account.save!

			elsif (xaction.op == :pay_system) then
				result = beneficiary?(xaction, true) \
					and Account.transfer(xaction.amount, xaction.primary.account, \
						admin_account(), xaction.amount)

			elsif (xaction.op == :withdraw) then
				result = beneficiary?(xaction, false) \
					and xaction.primary.account.withdraw(xaction.amount) \
					and xaction.primary.account.save!

			elsif (xaction.op == :transfer) then
				raise "transfer not supported"

			else
				raise "unsupported op '#{op}'"
			end
		else
			return false
		end
		result
	end

	private

		# Validates existence (or absence) of beneficiary in xaction
		def beneficiary?(xaction, need)
			if need then
				raise "please specify second party for op '#{xaction.other_party}'" \
					if xaction.other_party.nil?
			else
				raise "beneficiary party specified for op '#{xaction.other_party}' not needed" \
					unless xaction.other_party.nil?
			end
			return true
		end
end

class Xaction < ActiveRecord::Base

	TRANSACTION_ACCOUNT_OPS = { \
		reserve:		"FUNDS RESERVE", \
		release:		"FUNDS RELEASE", \
		credit:			"CREDIT", \
		pay_system:		"SYSTEM CHARGE",
		bond_transfer:	"BOND PAID OUT", \
		fee_change:		"FEES AWARDED", \
		deposit:		"DEPOSIT", \
		withdraw:		"WITHDRAW", \
		transfer:		"TRANSFER", \
	}

	attr_accessible :op, :beneficiary
	monetize :amount_cents

	belongs_to :primary, class_name: Party, foreign_key: :primary_id
	belongs_to :beneficiary, class_name: Party, foreign_key: :beneficiary_id

	validates :op, :inclusion => TRANSACTION_ACCOUNT_OPS
	validates :primary, :presence => true
	validates :amount_cents, :numericality => true

	on_save	XactionCallback.new() 

	def admin_account()
		Account.admin_account.call
	end

end
