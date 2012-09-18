require 'spec_helper'

class Apple < Valuable
end

describe Valuable do

	describe "create an instance" do
		before(:each) do
			@party1 = FactoryGirl.create(:party1)
			@party2 = FactoryGirl.create(:party2)
		end

		it "should create a new instance given valid attributes" do
			@valuable = Apple.new()
			@valuable.contract_id = 1
			@valuable.value = Money.parse("$120")
			@valuable.origin = @party1 
			@valuable.disposition = @party1 
			@valuable.save!
		end
	end

	describe "manage funds" do

		before(:each) do
			@party1 = FactoryGirl.create(:party1)
			@party2 = FactoryGirl.create(:party2)
			@party1.user.account.set_funds(1000, 0)
			@party2.user.account.set_funds(1000, 0)
			@valuable = Valuable.new()
			@valuable.value = Money.parse("$120")
			@valuable.origin = @party1
			@valuable.disposition = @party1
			@valuable.contract_id = 1
		end

		it "should start out with state of :s_initial" do
			@valuable.machine_state_name.should be == :s_initial
		end

		it "should transition to :s_reserved when it receives a :reserve; party1's " \
				+ "funds should be reserved" do
			@valuable.reserve()
			@valuable.machine_state_name.should be == :s_reserved
			@valuable.origin.user.account.available_funds.should be == Money.parse("$880")
		end

		it "should transition to :s_initial when it receives a :release; party1's " \
				+ "funds should be released" do
			@valuable.reserve()
			@valuable.release()
			@valuable.origin.user.account.available_funds.should be == Money.parse("$1000")
			@valuable.machine_state_name.should be == :s_initial
		end

		it "should transition to :s_transferred when it receives a :transfer; party1's " \
				+ "funds should be transferred to party2" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.origin.user.account.available_funds.should be == Money.parse("$880")
			@valuable.disposition.user.account.available_funds.should be == Money.parse("$1120")
			@valuable.machine_state_name.should be == :s_transferred
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
			@valuable.machine_state_name.should be == :s_reserved_4_dispute
		end

		it "should give party1 the valuable (plus restore previous funds transfer) if ruling " \
				+ "is in party1's favor (:adjudicate event)" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.dispute()
			@valuable.adjudicate(:for_plaintif => true)

			@valuable.origin.user.account.available_funds.should be == Money.parse("$1120")
			@valuable.origin.user.account.total_funds.should be == Money.parse("$1120")
			@valuable.disposition.user.account.available_funds.should be == Money.parse("$880")
			@valuable.disposition.user.account.total_funds.should be == Money.parse("$880")
			@valuable.machine_state_name.should be == :s_transferred
		end

		it "should free the hold on party2's funds if ruling " \
				+ "is in party2's favor (:adjudicate event)" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.dispute()
			@valuable.adjudicate(:for_plaintif => false)

			@valuable.origin.user.account.available_funds.should be == Money.parse("$880")
			@valuable.origin.user.account.total_funds.should be == Money.parse("$880")
			@valuable.disposition.user.account.available_funds.should be == Money.parse("$1120")
			@valuable.disposition.user.account.total_funds.should be == Money.parse("$1120")
			@valuable.machine_state_name.should be == :s_transferred
		end
	end
end
