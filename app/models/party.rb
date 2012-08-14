##############################################################################################
#
# Party -- connects a user and her Account to a role in a Transaction.
#
# One or more Xactions describe how money moves around with respect to her account.
#
# If is_bonded is true, then we have already reserved funds sufficient to cover the worst
# case scenario for this transaction (bond + fees).  We move funds for different purposes
# separately but atomically.  For instance, to end a faulted transaction, we simultaneously
# clear the (previously reserved) faulting party's funds in the amount of the bond and transfer
# it to the other party.  However, when we clear the fees and pay them to the system, this
# is a new Xaction.
#
##############################################################################################
class Party < ActiveRecord::Base

	belongs_to	:transaction
	belongs_to	:user
	has_many	:as_primary, class_name: Xaction, foreign_key: :primary
	has_many	:as_beneficiary, class_name: Xaction, foreign_key: :beneficiary

	validates :user, presence: true
	validates :transaction, presence: true
	validates :role, presence: true, inclusion: Transaction.roles 

	after_create :init

	attr_accessor :user_id, :is_bonded, :role 

	#
	# Reserve enough money to cover the worst case outcome of the Transaction.
	#
	def bond()
		reserve = as_primary.create(op: :reserve)
		reserve.amount = @bond_amnt + @fees_amnt
		reserve.save!()
		self.is_bonded
		save!
	end

	# 
	# System collects fees, deposit is released/returned back to Party
	#
	def release_bond()
		release = @as_primary.create(op: :release)
		release.amount = @bond_amnt
		release.save!()
		pay_system()
		self.is_bonded = false
		save!()
	end

	#
	# All the Party's money associated with this transaction is released/returned, including
	# fees.
	#
	def cancel_bond()
		xaction = as_primary.create(op: :release)
		xaction.amount = @bond_amnt+@fees_amnt
		@is_bonded = false
		xaction.!save()
		save!()
	end

	#
	# Release and pay user's bond to other_party, then release and pay this Party's fees 
	#
	def award_bond(other_party)
		bond_xfer = as_primary.create(op: :bond_transfer, beneficiary: other_party)
		bond_xfer.amount = @bond_amnt
		@is_bonded = false
		bond_xfer.save!()
		pay_system()
		save!()
	end

# TODO: fix this fcn.  Review remaining code in this file.  Write tests for Account, Xaction,
# Party.  Think about two-party assumpions and fees.  Then start on statemachine.
	#
	# Release this Party from some or all fees and shift them to other_party. Fees to be paid
	# by this user are expressed as a decimal fraction of the fees they would normally owe.
	# with the rest getting shifted to the other party, e.g,
	#
	#  This means increasing or decreasing held funds for each party too.
	#
	def award_fees(portion, other_party)
		raise "portion must be between 0 and 1" unless portion >= 0.0 and portion <= 1.0

		self_fees = Money.parse(transaction.fees_for(self.role))
		others_fees = Money.parse(transaction.fees_for(other_party.role))
		total_fees = self_fees + others_fees
		new_self_fees = (self_fees * portion).round
		new_others_fees = total_fees - new_self_fees
		current_self_fees = self.fees_amount
		current_others_fees = other_party.fees_amount

		self_fees_delta = new_self_fees - current_self_fees
		fees_xfer = nil
		if self_fees_delta > 0 then
			fees_xfer = as_primary.create(op: :reserve)
			fees_xfer.amount = self_fees_delta
		else
			fees_xfer = as_primary.create(op: :release)
			fees_xfer.amount = self_fees_delta
		end
		fees_xfer.save!
		self.fees_amount = new_self_fees
		self.is_bonded = true
		self.save!

		others_fees_delta = new_others_fees - current_others_fees
		if others_fees_delta > 0 then
			fees_xfer = other_party.as_primary.create(op: :reserve)
			fees_xfer.amount = others_fees_delta
		else
			fees_xfer = other_party.as_primary.create(op: :release)
			fees_xfer.amount = others_fees_delta
		end
		fees_xfer.save!
		other_party.fees_amount = new_others_fees
		other_party.is_bonded = true
		other_party.save!

		true
	end
	
	#
	# Determine if this party is bonded: has funds reserved to cover worst case outcome
	# of transaction.
	#
	def bonded?()
		self.is_bonded
	end

	def to_s
		"user = #{user}, role = #{role}, transaction = #{transaction}"
	end

	private

		def init()
			self.is_bonded ||= false
			self.fees_amnt ||= Money.parse(transaction.fees_for(self.role))
			self.bond_amnt ||= Money.parse(transaction.bond_amount(self.role))
		end

		# helper
		def pay_system()
			fees = xactions.create(op: :pay_system, as_primary: self.id)
			fees.amount = @fees_amnt
			fees.save!
		end
end
