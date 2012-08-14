require 'spec_helper'

describe Xaction do
	before(:each) do
		@buyer = FactoryGirl.build(:buyer_user)
		@seller = FactoryGirl.build(:seller_user)
	end

	it "should have a working reserve()" do
		@xaction = @buyer.account.build_transaction(op: :reserve, beneficiary: )
		
	end

	it "should have a working release()" do
		@xaction = @buyer.account.build_transaction(op: :release)

	end
end
