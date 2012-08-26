require 'spec_helper'

describe Xaction do

	before(:all) do
		@buyer = FactoryGirl.build(:buyer_user)
		@buyer_account = @buyer.account
		@seller = FactoryGirl.build(:seller_user)
		@seller_account = @seller.account
	end

	before(:each) do
		@buyer_account.set_funds(100, 50)
		@seller_account.set_funds(100, 50)
	end

	it "should create valid instances for every operation" do
		Xaction::TRANSACTION_ACCOUNT_OPS.each do |record|
			op, operands = record[0], record[2]
			xaction = Xaction.new(op: op)
			xaction.primary = @buyer_account
			xaction.beneficiary = ((operands == 2) ? @seller_account : nil)
			xaction.amount = Money.parse("$1.00")
			xaction.hold = Money.parse("$0.00")
			xaction.save
			xaction.primary.new_record?.should be_false
			xaction.beneficiary.new_record?.should be_false unless xaction.beneficiary.nil?
		end
	end

	it "should have a working reserve()" do
		@xaction = Xaction.new(op: :reserve)
		@xaction.primary = @buyer_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$0.00")
		@buyer_account.available_funds.should be == Money.parse("$50.00")
		@xaction.save!
		@buyer_account.available_funds.should be == Money.parse("$0.00")
	end

	it "should have a working release()" do
		@xaction = Xaction.new(op: :release)
		@xaction.primary = @buyer_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$0.00")
		@xaction.save!
		@buyer_account.available_funds.should be == Money.parse("$100.00")
	end

	it "should have a working transfer()" do
		@xaction = Xaction.new(op: :transfer)
		@xaction.primary = @buyer_account
		@xaction.beneficiary= @seller_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$0.00")
		@xaction.save!
		@buyer_account.available_funds.should be == Money.parse("$0.00")
		@seller_account.available_funds.should be == Money.parse("$100.00")
	end

	it "should release funds in a transfer() if so requested" do
		@xaction = Xaction.new(op: :transfer)
		@xaction.primary = @buyer_account
		@xaction.beneficiary= @seller_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$50.00")
		@xaction.save!
		@buyer_account.available_funds.should be == Money.parse("$50.00")
		@seller_account.available_funds.should be == Money.parse("$100.00")
	end

	it "should have a working deposit()" do
		@xaction = Xaction.new(op: :deposit)
		@xaction.primary = @seller_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$0.00")
		@xaction.save!
		@seller_account.available_funds.should be == Money.parse("$100.00")
	end

	it "should be possible to hold funds on a deposit()" do
		@xaction = Xaction.new(op: :deposit)
		@xaction.primary = @seller_account
		@xaction.amount = Money.parse("$50.00")
		@xaction.hold = Money.parse("$25.00")
		@xaction.save!
		@seller_account.available_funds.should be == Money.parse("$75.00")
	end

	it "should have a working withdraw()" do
		@xaction = Xaction.new(op: :withdraw)
		@xaction.primary = @seller_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$0.00")
		@xaction.save!
		@seller_account.available_funds.should be == Money.parse("$0.00")
	end

	it "should flag unsupported operations" do
		@xaction = Xaction.new(op: :xaction)
		@xaction.primary = @buyer_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$0.00")
		expect {@xaction.save!}.should raise_error
	end

	it "should propagate errors from Account" do
		@xaction = Xaction.new(op: :reserve)
		@xaction.primary = @buyer_account
		@xaction.amount = Money.parse("$150.00") 
		@xaction.hold = Money.parse("$0.00")
		expect {@xaction.save!}.should raise_error
	end

	it "should propagate errors from Account" do
		@xaction = Xaction.new(op: :transfer)
		@xaction.primary = @buyer_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$200.00")
		expect {@xaction.save!}.should raise_error
	end

	it "should allow reserve and release to work together" do
		@xaction = Xaction.new(op: :reserve)
		@xaction.primary = @buyer_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$0.00")
		@buyer_account.available_funds.should be == Money.parse("$50.00")
		@xaction.save!
		@buyer_account.available_funds.should be == Money.parse("$0.00")

		@xaction = Xaction.new(op: :release)
		@xaction.primary = @buyer_account
		@xaction.amount = Money.parse("$50.00") 
		@xaction.hold = Money.parse("$0.00")
		@xaction.save!
		@buyer_account.available_funds.should be == Money.parse("$50.00")
		@buyer_account.total_funds.should be == Money.parse("$100.00")
	end
end
