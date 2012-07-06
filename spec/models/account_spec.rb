require 'spec_helper'

describe Account do
	
	before(:each) do
		@user_without_account = FactoryGirl.build(:user_without_account)
		@user_with_account = FactoryGirl.build(:user)
		@account = @user_with_account.account
		@attr = FactoryGirl.attributes_for(:account)
	end

	it "should create a new instance given valid attributes" do
		@user = FactoryGirl.build(:user_without_account)
		@account = Account.create!(@attr)
	end

	describe "divide by zero" do
		it "3 / 0 should not be allowed" do
			expect {3 / 0}.to raise_error
		end
	end

	describe "exec_xaction" do
		it "should not accept invalid arguments" do
			expect {@account.exec_xaction(:foo, 5)}.to raise_error
		end
	end

	describe "get_funds" do
		it "should not accept invalid arguments" do
			expect {@account.get_funds(:foo)}.to raise_error
		end
	end

	it "should have a user attribute" do
		@account = @user_with_account.account
		@account.should respond_to(:user)
	end

	it "should have the right associated user" do
		@account = @user_with_account.account
		@account.user.should == @user_with_account
	end

	it "should contain no money (when new)" do
		@account = @user_with_account.account
		assert_equal(0, @account.get_funds(:total))
		assert_equal(0, @account.get_funds(:available))
	end

	it "shouldn't allow mass-assignment of funds" do
		@attr.merge!(available_funds: 100, total_funds: 10)
		expect {@user_without_account.build_account(@attr)}.to raise_error
	end

	it "should add funds to :available_funds correctly" do
		amnt = 150
		@account.exec_xaction(:total, amnt)
		@account.get_funds(:total).should == amnt
	end

	it "should should clear funds correctly" do
		amnt = 150
		@account.exec_xaction(:total, amnt)
		@account.exec_xaction(:available, amnt)
		@account.get_funds(:total).should == amnt
	end

	it "should display :available funds correctly" do
		amnt = 150
		@account.exec_xaction(:total, amnt)
		@account.exec_xaction(:available, amnt)
		@account.get_funds(:available).should == amnt
	end

	it "should display :total funds correctly" do
		amnt = 150
		@account.exec_xaction(:total, amnt)
		@account.exec_xaction(:available, amnt)
		@account.get_funds(:total).should == amnt
	end

	it "should allow negative total funds" do
		amnt = -150
		@account.exec_xaction(:total, amnt)
		@account.exec_xaction(:available, amnt)
		@account.should be_valid 
	end

	it "should allow negative available funds" do
		amnt = -150
		@account.exec_xaction(:total, amnt)
		@account.exec_xaction(:available, amnt)
		@account.should be_valid 
	end

	it "should not allow available funds to exceed total funds" do
		amnt = -150
		@account.exec_xaction(:available, amnt)
		@account.exec_xaction(:total, amnt - 10)
		@account.should_not be_valid
	end

end
