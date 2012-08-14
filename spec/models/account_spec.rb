require 'spec_helper'

describe Account do
	
	MZERO = Money.parse(0) 
	TWO_HUNDRED = Money.parse(200)
	ONE_FIFTY = Money.parse(150)
	HUNDRED = Money.parse(100)
	NINETY = Money.parse(90)
	BADMONEY = lambda {Money.parse("BAD")}
	FIFTY = Money.parse(50)
	TWENTY_FIVE = Money.parse(25)
	TEN = Money.parse(10)
	TWO = Money.parse(2)

	before(:each) do
		@user = FactoryGirl.build(:user_without_account)
		@attr = FactoryGirl.attributes_for(:account)
		@account = @user.build_account(@attr)
	end

	# Account creation
	it "should create a new instance given valid attributes" do
		@account.save!
	end

	it "should contain no money when new" do
		@account.available_funds().should be == MZERO
		@account.total_funds().should be == MZERO
	end

	it "it should save with valid state" do
		@account.set_funds(HUNDRED, FIFTY)
		@account.save!
	end

	it "it should not save with invalid state" do
		expect {@account.set_funds(BADMONEY.call, FIFTY)}.should raise_error
	end


	it "it should not save with invalid state" do
		@account.set_funds(HUNDRED, TWO_HUNDRED)
		expect {@account.save!}.should raise_error
	end

	it "it should not save with invalid state" do
		expect {@account.set_funds(HUNDRED, BADMONEY.call)}.should raise_error
	end

	it "shouldn't allow mass-assignment of funds" do
		@attr.merge!(available_funds: 100, total_funds: 10)
		expect {@user.create_account!(@attr)}.should raise_error
	end

	# user
	it "should have a user attribute" do
		@account.should respond_to(:user)
	end

	it "should have the right associated user" do
		@user.account.should == @account
	end

	describe "deposits" do

		it "should respond to deposit" do
			@account.should respond_to :deposit
		end

		it "should deposit the right amount" do
			@account.deposit(HUNDRED, MZERO)
			@account.available_funds.should be == HUNDRED 
		end

		it "should deposit the right amount" do
			@account.deposit(HUNDRED, FIFTY)
			@account.available_funds.should be == FIFTY 
		end

		it "should return the right amount" do
			@account.deposit(HUNDRED, FIFTY)
			@account.total_funds.should be == HUNDRED 
		end

		it "it should not accept bad arguments" do
			expect {@account.deposit(-HUNDRED, -HUNDRED)}.should raise_error
		end

		it "it should not accept 0 argument for first arg" do
			expect {@account.deposit(MZERO, MZERO)}.should raise_error 
		end
	end

	# withdraw
	describe "withdraw funds" do
		
		it "should have a withdraw method" do
			@account.should respond_to :withdraw
		end

		it "should throw error attempting to reserve too much" do
			amnt = HUNDRED 
			@account.set_funds(amnt, MZERO)
			expect {@account.reserve(amnt + TWO)}.should raise_error 
		end

		it "should correctly influence available amount" do
			amnt = HUNDRED 
			@account.set_funds(amnt, MZERO)
			@account.reserve(FIFTY)
			@account.withdraw(TWENTY_FIVE)
			@account.available_funds.should be == TWENTY_FIVE
		end

		it "should correctly influence total amount" do
			amnt = HUNDRED 
			@account.set_funds(amnt, MZERO)
			@account.reserve(FIFTY)
			@account.withdraw(FIFTY)
			@account.total_funds.should be == FIFTY 
		end

		it "should not accept 0" do
			expect {@account.withdraw(MZERO)}.should raise_error
		end

		it "should not accept bad arguments" do
			expect {@account.withdraw(BADMONEY.call)}.should raise_error
		end

	end

	# available funds
	describe "available funds" do

		it "should respond to available_funds" do
			@account.should respond_to :available_funds
		end

		it "should return the right amount" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(HUNDRED)
			@account.available_funds.should be == MZERO 
		end

		it "should return the right amount" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(FIFTY)
			@account.available_funds.should be == FIFTY 
		end

		it "should not be able to reserve more than is available" do
			@account.set_funds(FIFTY, MZERO)
			expect {@account.reserve(HUNDRED)}.should raise_error
		end

		it "funds should be available" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(FIFTY)
			@account.available_funds.should be == FIFTY
		end

		it "should not allow bad available funds" do
			expect {@account.reserve(BADMONEY.call)}.should raise_error
		end

	end

	describe "total funds" do

		it "should respond to total funds" do
			@account.should respond_to :total_funds
		end

		it "should return the right amount" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(TWO)
			@account.total_funds.should be == HUNDRED 
		end
		it "should return the right amount" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(HUNDRED)
			@account.total_funds.should be == HUNDRED 
		end

	end

	describe "sufficient funds" do
		it "should respond to sufficient_funds" do
			@account.should respond_to :sufficient_funds?
		end

		it "should know when we are ok" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(NINETY)
			@account.sufficient_funds?(TEN).should be_true
		end

		it "should know when we aren't" do
			@account.set_funds(HUNDRED, MZERO)
			@account.sufficient_funds?(ONE_FIFTY).should_not be_true
		end

		it "should not accept bad arguments" do
			expect {@account.sufficient_funds?(BADMONEY.call)}.should raise_error
		end
	end

	describe "clearing funds" do

		it "should respond to clear" do
			@account.should respond_to :clear
		end

		it "should not accept invalid arguments" do
			@account.set_funds(HUNDRED, TEN)
			expect {@account.clear(TEN)}.should_not raise_error
			expect {@account.clear(HUNDRED)}.should raise_error
		end

		it "should clear correctly" do
			amnt = ONE_FIFTY 
			@account.set_funds(amnt, amnt)
			@account.clear(amnt)
			@account.available_funds.should be == amnt
		end

		it "should not accept a bad argument" do
			expect {@account.clear(BADMONEY.call)}.should raise_error
		end

		it "should not accept 0 argument" do
			expect {@account.clear(MZERO)}.should raise_error
		end
	end

	describe "reserving funds" do
		it "should respond to reserving funds" do
			@account.should respond_to :reserve
		end

		it "should not accept 0" do
			@account.set_funds(HUNDRED, MZERO)
			expect {@account.reserve(MZERO)}.should raise_error
		end

		it "should recognize reserved funds" do 
			amnt = HUNDRED 
			res = TWO 
			@account.set_funds(amnt, MZERO)
			@account.reserve(res)
			@account.available_funds.should be == amnt - res
		end

		it "should recognize reserved funds" do 
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(FIFTY)
			@account.available_funds.should be == FIFTY 
		end
	end

end

describe "Account tranfers" do
	before(:each) do
		@from_user = FactoryGirl.build(:user_without_account)
		@to_user = FactoryGirl.build(:user_without_account)
		@attr = FactoryGirl.attributes_for(:account)

		@from_account = @from_user.build_account(@attr)
		@from_account.set_funds(HUNDRED, FIFTY)

		@to_account = @to_user.build_account(@attr)
		@to_account.set_funds(HUNDRED, FIFTY)
	end

	describe "transferring funds" do

		it "should respond to transfer" do
			Account.should respond_to :transfer
		end

		it "requested funds should clear first" do
			Account.transfer(FIFTY, @from_account, @to_account, FIFTY)
			@from_account.available_funds.should be == FIFTY 
		end

		it "available funds should be correct" do
			Account.transfer(FIFTY, @from_account, @to_account)
			@from_account.available_funds.should be == MZERO 
		end

		it "available funds should be correct" do
			Account.transfer(FIFTY, @from_account, @to_account, MZERO)
			@from_account.available_funds.should be == MZERO 
		end

		it "total funds should be correct" do
			Account.transfer(FIFTY, @from_account, @to_account)
			@from_account.total_funds.should be == FIFTY 
		end

		it "2nd account should be credited" do
			Account.transfer(FIFTY, @from_account, @to_account)
			@to_account.available_funds.should be == FIFTY 
		end

		it "2nd account should be credited" do
			Account.transfer(FIFTY, @from_account, @to_account)
			@to_account.total_funds.should be == ONE_FIFTY 
		end

		it "should save correctly" do
			@to_account.total_funds.should be == HUNDRED 
			@from_account.total_funds.should be == HUNDRED 
			@from_account.available_funds.should be == FIFTY 
			@to_account.available_funds.should be == FIFTY 

			Account.transfer(FIFTY, @from_account, @to_account)
			@from_account.reload
			@to_account.reload

			@to_account.total_funds.should be == ONE_FIFTY 
			@from_account.total_funds.should be == FIFTY 
			@from_account.available_funds.should be == MZERO 
		end
	end

end
