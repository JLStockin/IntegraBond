require 'spec_helper'

TWO_HUNDRED = Money.parse("$200")
ONE_FIFTY = Money.parse("$150")
HUNDRED = Money.parse("$100")
NINETY = Money.parse("$90")
BADMONEY = lambda {Money.parse("BAD")}
FIFTY = Money.parse("$50")
TWENTY_FIVE = Money.parse("$25")
TEN = Money.parse("$10")
TWO = Money.parse("$2")

describe "Account creation" do
	
	before(:each) do
		@user = FactoryGirl.create(:seller_user)
		@account = FactoryGirl.build(:seller_account)
		@user.account = @account
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
		@account.save!
		expect {@account.set_funds(HUNDRED, FIFTY)}.should_not raise_error
	end

	it "it should not save when deposit funds don't parse" do
		@account.save!
		expect {@account.set_funds(BADMONEY.call, FIFTY)}.should raise_error
	end

	it "it should not save when reserve/funds ratio is > 1/1" do
		@account.save!
		expect {@account.set_funds(HUNDRED, TWO_HUNDRED)}.should raise_error
	end

	it "it should not save when reserve funds don't parse" do
		@account.save!
		expect {@account.set_funds(HUNDRED, BADMONEY.call)}.should raise_error
	end

	it "shouldn't allow mass-assignment of funds" do
		expect {@user.create_account!(funds: 100, hold_funds: 50)}.should raise_error
	end

	# user
	it "should have a user attribute" do
		@account.should respond_to(:user)
	end

	it "should have the right associated user" do
		@account.save!
		@user.account.should == @account
	end

end

describe "Account" do
	before(:each) do
		@user = FactoryGirl.build(:seller_user)
		@account = @user.create_account()
	end

	# available funds
	describe "available funds" do

		it "should respond to available_funds" do
			@account.should respond_to :available_funds
		end

		it "should return zero" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(HUNDRED)
			@account.available_funds.should be == MZERO 
		end

		it "should return right amount" do
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

		it "should not create a transaction" do
			@account.set_funds(HUNDRED, MZERO)
			expect {
				@account.available_funds()
			}.to_not change { Xaction.count }
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

		it "should know when we aren't ok" do
			@account.set_funds(HUNDRED, MZERO)
			@account.sufficient_funds?(ONE_FIFTY).should_not be_true
		end
		
		it "shouldn't create a transaction record" do
			@account.set_funds(HUNDRED, MZERO)
			expect {
				@account.sufficient_funds?(FIFTY)
			}.to_not change { Xaction.count }
		end

		it "should not accept bad arguments" do
			expect {@account.sufficient_funds?(BADMONEY.call)}.should raise_error
		end
	end

	describe "deposits" do

		it "should respond to deposit" do
			@account.should respond_to :deposit
		end

		it "should deposit" do
			@account.deposit(HUNDRED, MZERO)
			@account.available_funds.should be == HUNDRED 
		end

		it "should deposit and reserve" do
			@account.deposit(HUNDRED, FIFTY)
			@account.available_funds.should be == FIFTY 
		end

		it "should create the right transaction record" do
			@account.deposit(HUNDRED, FIFTY)
			xaction = @account.primaries.last
			xaction.should_not be_nil
			xaction.op.should be == :deposit.to_s
			xaction.primary.should be == @account 
			xaction.amount.should be == HUNDRED
			xaction.hold.should be == FIFTY
		end

		it "should be a credit" do
			@account.deposit(HUNDRED, FIFTY)
			xaction = @account.primaries.last
			xaction.credit_for?(@account).should be_true
		end

		it "should save the account" do
			@account.deposit(HUNDRED, FIFTY)
			@account.reload
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
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(FIFTY)
			@account.withdraw(FIFTY)
			@account.total_funds.should be == FIFTY 
		end

		it "should create the right transaction record" do
			@account.set_funds(HUNDRED, MZERO)
			@account.withdraw(FIFTY)
			xaction = @account.primaries.last
			xaction.should_not be_nil
			xaction.op.should be == :withdraw.to_s
			xaction.primary.should be == @account 
			xaction.amount.should be == FIFTY 
			xaction.hold.should be == 0 
		end

		it "should be a debit" do
			@account.set_funds(HUNDRED, FIFTY)
			@account.withdraw(FIFTY)
			xaction = @account.primaries.last
			xaction.credit_for?(@account).should be_false
		end

		it "should save the account" do
			@account.set_funds(HUNDRED, FIFTY)
			@account.withdraw(FIFTY)
			@account.reload
			@account.available_funds.should be == MZERO 
		end

		it "should not accept 0" do
			expect {@account.withdraw(MZERO)}.should raise_error
		end

		it "should not accept bad arguments" do
			expect {@account.withdraw(BADMONEY.call)}.should raise_error
		end

	end

	describe "deposit/withdraw combo" do

		it "should conclude where it started" do
			@account.deposit(HUNDRED, MZERO)
			@account.available_funds.should be == HUNDRED 
			@account.withdraw(HUNDRED)
			@account.reload
			@account.available_funds.should be == MZERO
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

		it "should create the right transaction record" do
			@account.set_funds(HUNDRED, HUNDRED)
			@account.clear(HUNDRED)
			xaction = @account.primaries.last
			xaction.should_not be_nil
			xaction.op.should be == :clear.to_s
			xaction.primary.should be == @account 
			xaction.amount.should be == HUNDRED 
			xaction.hold.should be == 0
		end

		it "should be a credit" do
			@account.set_funds(HUNDRED, HUNDRED)
			@account.clear(HUNDRED)
			xaction = @account.primaries.last
			xaction.credit_for?(@account).should be_true
		end

		it "should save the account" do
			@account.set_funds(HUNDRED, FIFTY)
			@account.clear(FIFTY)
			@account.reload
			@account.available_funds.should be == HUNDRED 
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

		it "should create the right transaction record" do
			@account.set_funds(HUNDRED, FIFTY)
			@account.reserve(FIFTY)
			xaction = @account.primaries.last
			xaction.should_not be_nil
			xaction.op.should be == :reserve.to_s
			xaction.primary.should be == @account 
			xaction.amount.should be == FIFTY 
			xaction.hold.should be == 0
		end

		it "should be a credit" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(HUNDRED)
			xaction = @account.primaries.last
			xaction.credit_for?(@account).should be_false
		end

		it "should save the account" do
			@account.set_funds(HUNDRED, FIFTY)
			@account.reserve(FIFTY)
			@account.reload
			@account.available_funds.should be == MZERO 
		end
	end

	describe "reserve/clear combo" do

		it "should conclude where it started" do
			@account.set_funds(HUNDRED, MZERO)
			@account.reserve(HUNDRED)
			@account.reload
			@account.available_funds.should be == MZERO 
			@account.clear(HUNDRED)
			@account.reload
			@account.available_funds.should be == HUNDRED 
		end
	end

end

describe "Account transfer" do
	before(:each) do
		@from_user = FactoryGirl.create(:seller_user)
		@to_user = FactoryGirl.create(:buyer_user)

		@from_account = @from_user.create_account()
		@to_account = @to_user.create_account()
	end

	it "should be a method on the Account class" do
		Account.should respond_to :transfer
	end

	it "should create the right transaction record" do
		@from_account.set_funds(HUNDRED, FIFTY)
		@to_account.set_funds(FIFTY, MZERO)
		Account.transfer(FIFTY, @from_account, @to_account)

		xaction = @from_account.primaries.last
		xaction.should_not be_nil
		xaction.op.should be == :transfer.to_s
		xaction.primary.should be == @from_account
		xaction.beneficiary.should be == @to_account
		xaction.amount.should be == FIFTY
		xaction.hold.should be == MZERO 

		xaction2 = @to_account.beneficiaries.last
		xaction.should be == xaction2
	end

	it "should be a debit for primary, credit for beneficiary" do
		@from_account.set_funds(HUNDRED, FIFTY)
		@to_account.set_funds(FIFTY, MZERO)
		Account.transfer(FIFTY, @from_account, @to_account)
		xaction = @from_account.primaries.last
		xaction.credit_for?(@from_account).should be_false
		xaction.credit_for?(@to_account).should be_true
	end

	describe "from origin account" do

		describe "without clearing some funds" do

			it "should succeed when there are sufficient funds" do
				@from_account.set_funds(HUNDRED, FIFTY)
				expect {
					Account.transfer(FIFTY, @from_account, @to_account)
				}.should_not raise_error
			end

			it "should fail for insufficient funds" do
				@from_account.set_funds(HUNDRED, HUNDRED)
				expect {
					Account.transfer(FIFTY, @from_account, @to_account, MZERO)
				}.should raise_error
			end

			it "available funds should be correct" do
				@from_account.set_funds(HUNDRED, FIFTY)
				Account.transfer(FIFTY, @from_account, @to_account)
				@from_account.available_funds.should be == MZERO 
			end

			it "total funds should be correct" do
				@from_account.set_funds(HUNDRED, FIFTY)
				Account.transfer(FIFTY, @from_account, @to_account)
				@from_account.total_funds.should be == FIFTY 
			end

			it "should save the account" do
				@from_account.set_funds(HUNDRED, FIFTY)
				Account.transfer(FIFTY, @from_account, @to_account)
				@from_account.reload
				@from_account.available_funds.should be == MZERO 
			end
		end

		describe "with clearing funds" do

			it "should fail for insufficient funds" do
				@from_account.set_funds(HUNDRED, HUNDRED)
				expect {
					Account.transfer(FIFTY, @from_account, @to_account, MZERO)
				}.should raise_error
			end

			it "should succeed when funds should clear first" do
				@from_account.set_funds(HUNDRED, HUNDRED)
				expect {
					Account.transfer(FIFTY, @from_account, @to_account, FIFTY)
				}.should_not raise_error
			end

			it "available funds should be correct" do
				@from_account.set_funds(TWO_HUNDRED, FIFTY)
				Account.transfer(FIFTY, @from_account, @to_account, FIFTY)
				@from_account.available_funds.should be == ONE_FIFTY 
			end

			it "total funds should be correct" do
				@from_account.set_funds(TWO_HUNDRED, FIFTY)
				Account.transfer(FIFTY, @from_account, @to_account, FIFTY)
				@from_account.total_funds.should be == ONE_FIFTY 
			end

			it "should save the account" do
				@from_account.set_funds(HUNDRED, FIFTY)
				Account.transfer(FIFTY, @from_account, @to_account, FIFTY)
				@from_account.reload
				@from_account.available_funds.should be == FIFTY 
				@from_account.total_funds.should be == FIFTY 
			end
		end

	end

	describe "to beneficiary account" do

		describe "without reserved funds" do
			it "should be credited" do
				@from_account.set_funds(HUNDRED, FIFTY)
				@to_account.set_funds(FIFTY, MZERO)
				Account.transfer(FIFTY, @from_account, @to_account)
				@to_account.available_funds.should be == HUNDRED 
				@to_account.available_funds.should be == @to_account.total_funds 
			end
		end

		describe "with reserved funds" do
			it "should be credited" do
				@from_account.set_funds(HUNDRED, FIFTY)
				@to_account.set_funds(FIFTY, FIFTY)
				Account.transfer(FIFTY, @from_account, @to_account)
				@to_account.available_funds.should be == FIFTY 
				@to_account.total_funds.should be == HUNDRED
			end
		end

		it "should save correctly" do
			@from_account.set_funds(HUNDRED, FIFTY)
			@to_account.set_funds(FIFTY, FIFTY)

			Account.transfer(FIFTY, @from_account, @to_account)
			@to_account.reload

			@to_account.total_funds.should be == HUNDRED 
			@to_account.available_funds.should be == FIFTY 
		end
	end

end
