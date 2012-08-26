require 'spec_helper'

class Apple < Valuable
end

describe Valuable do
	before(:all) do
		@party1 = FactoryGirl.build(:party_party1)
		@party2 = FactoryGirl.build(:party_party2)
	end

	it "should create a new instance given valid attributes" do
		@valuable = Valuable.new()
		@valuable.value = Money.parse("$120")
		@valuable.origin = @party1 
		@valuable.disposition = @party1 
		@valuable.save!
	end

	before(:each) do
		@party1.user.account.set_funds(100000, 0)
		@party2.user.account.set_funds(100000, 0)
		@valuable = Valuable.new()
		@valuable.value = Money.parse("$120")
		@valuable.origin = @party1
		@valuable.disposition = @party1
	end

	it "should start out with state of :s_initial" do
		@valuable.state.should be == :s_initial
	end

	it "should transition to :s_reserved when it receives a :reserve; party1's " \
			+ "funds should be reserved" do
		@valuable.reserve()
		@valuable.state.should be == :s_reserved
		@valuable.origin.user.account.available_funds.should be == Money.parse("$880")
	end

	it "should transition to :s_released when it receives a :release; party1's " \
			+ "funds should be released" do
		@valuable.reserve()
		@valuable.release()
		@valuable.origin.user.account.available_funds.should be == Money.parse("$1000")
		@valuable.state.should be == :s_initial
	end

	it "should transition to :s_released when it receives a :release; party1's " \
			+ "funds should be released" do
		@valuable.release()
		@valuable.origin.user.account.available_funds.should be == Money.parse("$1000")
		@valuable.state.should be == :s_initial
	end

	it "should transition to :s_transferred when it receives a :transfer; party1's " \
			+ "funds should be transferred to party2" do
		@valuable.reserve()
		@valuable.disposition = @party2
		@valuable.transfer()
		@valuable.origin.user.account.available_funds.should be == Money.parse("$880")
		@valuable.disposition.user.account.available_funds.should be == Money.parse("$1120")
		@valuable.state.should be == :s_transferred
	end

	it "should transition to :s_reserved when it receives a :dispute; " \
			+ "there should be a 2X hold on party2's funds" do
		@valuable.reserve()
		@valuable.disposition = @party2
		@valuable.transfer()
		@valuable.dispute()

		@valuable.origin.user.account.available_funds.should be == Money.parse("$880")
		@valuable.origin.user.account.total_funds.should be == Money.parse("$880")
		@valuable.disposition.user.account.available_funds.should be == Money.parse("$880")
		@valuable.disposition.user.account.total_funds.should be == Money.parse("1120")
		@valuable.state.should be == :s_reserved
	end

	it "should give party1 the valuable (plus restore previous funds transfer) if ruling " \
			+ "is in party1's favor (:adjudicate event)" do
		@valuable.reserve()
		@valuable.disposition = @party2.user.account
		@valuable.transfer()
		@valuable.dispute()
		@valuable.abjudicate(true)

		@valuable.origin.user.account.available_funds.should be == Money.parse("$1120")
		@valuable.origin.user.account.total_funds.should be == Money.parse("$1120")
		@valuable.disposition.user.account.available_funds.should be == Money.parse("$880")
		@valuable.disposition.user.account.total_funds.should be == Money.parse("$880")
		@valuable.state.should be == :s_initial
	end

	it "should free the hold on party2's funds if ruling " \
			+ "is in party2's favor (:adjudicate event)" do
		@valuable.reserve()
		@valuable.disposition = @party2.user.account
		@valuable.transfer()
		@valuable.dispute()
		@valuable.abjudicate(false)

		@valuable.origin.user.account.available_funds.should be == Money.parse("$880")
		@valuable.origin.user.account.total_funds.should be == Money.parse("$880")
		@valuable.disposition.user.account.available_funds.should be == Money.parse("$1120")
		@valuable.disposition.user.account.total_funds.should be == Money.parse("$1120")
		@valuable.state.should be == :s_initial
	end
end
