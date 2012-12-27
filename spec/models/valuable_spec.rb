require 'spec_helper'

class Apple < Valuable
	ASSET = false
end

class Pear < Valuable
	ASSET = true
end

shared_examples_for "any valuable class" do

	it "should create a new instance given valid attributes" do
		valuable = @klass.new()
		valuable.tranzaction_id = 1
		valuable.value = Money.parse("$120")
		valuable.origin = @party1 
		valuable.disposition = @party1 
		valuable.should be_valid 
	end
end

shared_examples_for "any valuable" do

	it "should start out with state of :s_initial" do
		@valuable.machine_state_name.should be == :s_initial
	end

	it "should transition to :s_initial when they receive a :release; party1's " \
			+ "funds should be released too" do
		@valuable.reserve()
		@valuable.release()
		@valuable.origin.contact.user.account.available_funds.should be == Money.parse("$1000")
		@valuable.machine_state_name.should be == :s_initial
	end
end

def create_parties
	@party1 = FactoryGirl.create(:party1)
	@party1.contact.user.account.set_funds(1000, 0)

	@party2 = FactoryGirl.create(:party2)
	@party2.contact.user.account.set_funds(1000, 0)
end

def config_valuable(valuable)
	@valuable.value = Money.parse("$120")
	@valuable.origin = @party1
	@valuable.disposition = @party1
	@valuable.tranzaction_id = 1
	@valuable
end

describe Valuable do

	describe "that's not an asset" do

		before(:each) do
			create_parties()
			@valuable = Apple.new()
			@valuable = config_valuable(@valuable)
			@valuable.save!
			@klass = Apple
		end

		it_behaves_like "any valuable class"
		it_behaves_like "any valuable"

		it "should transition to :s_reserved when it receives a :reserve; party1's " \
				+ "funds should be reserved" do
			@valuable.reserve()
			@valuable.machine_state_name.should be == :s_reserved
			@valuable.origin.contact.user.account.available_funds.should be == Money.parse("$880")
		end

		it "should transition to :s_transferred when it receives a :transfer; party1's " \
				+ "funds should be transferred to party2" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse("$880")
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse("$1120")
			@valuable.machine_state_name.should be == :s_transferred
		end

		it "should transition to :s_reserved when it receives a :dispute; " \
				+ "there should be a 2X hold on party2's funds" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.dispute()

			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse("$880")
			@valuable.origin.contact.user.account.total_funds.should be \
				== Money.parse("$880")
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse("$880")
			@valuable.disposition.contact.user.account.total_funds.should be \
				== Money.parse("1120")
			@valuable.machine_state_name.should be == :s_reserved_4_dispute
		end

		it "should give party1 the valuable (plus restore previous funds transfer) if ruling " \
				+ "is in party1's favor (:adjudicate event)" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.dispute()
			@valuable.adjudicate(:for_plaintif => true)

			@valuable.origin.contact.user.account.available_funds.should be == Money.parse("$1120")
			@valuable.origin.contact.user.account.total_funds.should be == Money.parse("$1120")
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse("$880")
			@valuable.disposition.contact.user.account.total_funds.should be == Money.parse("$880")
			@valuable.machine_state_name.should be == :s_transferred
		end

		it "should free the hold on party2's funds if ruling " \
				+ "is in party2's favor (:adjudicate event)" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.dispute()
			@valuable.adjudicate(:for_plaintif => false)

			@valuable.origin.contact.user.account.available_funds.should be == Money.parse("$880")
			@valuable.origin.contact.user.account.total_funds.should be == Money.parse("$880")
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse("$1120")
			@valuable.disposition.contact.user.account.total_funds.should be == Money.parse("$1120")
			@valuable.machine_state_name.should be == :s_transferred
		end
	end

	describe "that is an asset" do

		before(:each) do
			create_parties()
			@valuable = Pear.new()
			@valuable = config_valuable(@valuable)
			@valuable.save!
			@klass = Pear 
		end

		it_behaves_like "any valuable class"
		it_behaves_like "any valuable"

		it "should transition to :s_reserved when it receives a :reserve; party1's " \
				+ "funds should not be reserved" do
			@valuable.reserve()
			@valuable.machine_state_name.should be == :s_reserved
			@valuable.origin.contact.user.account.available_funds.should be == Money.parse("$1000")
		end

		it "should transition to :s_transferred when it receives a :transfer; party1's " \
				+ "funds should not be transferred to party2" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse("$1000")
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse("$1000")
			@valuable.machine_state_name.should be == :s_transferred
		end

		it "should transition to :s_reserved when it receives a :dispute; " \
				+ "there shouldn't be a hold on party2's funds" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.dispute()

			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse("$1000")
			@valuable.origin.contact.user.account.total_funds.should be \
				== Money.parse("$1000")
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse("$1000")
			@valuable.disposition.contact.user.account.total_funds.should be \
				== Money.parse("1000")
			@valuable.machine_state_name.should be == :s_reserved_4_dispute
		end

		it "should give party1 the valuable if ruling " \
				+ "is in party1's favor (:adjudicate event)" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.dispute()
			@valuable.adjudicate(:for_plaintif => true)

			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse("$1000")
			@valuable.origin.contact.user.account.total_funds.should be == \
				Money.parse("$1000")
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse("$1000")
			@valuable.disposition.contact.user.account.total_funds.should be == \
				Money.parse("$1000")
			@valuable.machine_state_name.should be == :s_transferred
		end

		it "should be no hold on party2's funds if ruling " \
				+ "is in party2's favor (:adjudicate event)" do
			@valuable.reserve()
			@valuable.disposition = @party2
			@valuable.transfer()
			@valuable.dispute()
			@valuable.adjudicate(:for_plaintif => false)

			@valuable.origin.contact.user.account.available_funds.should be == Money.parse("$1000")
			@valuable.origin.contact.user.account.total_funds.should be == Money.parse("$1000")
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse("$1000")
			@valuable.disposition.contact.user.account.total_funds.should be == \
				Money.parse("$1000")
			@valuable.machine_state_name.should be == :s_transferred
		end
	end
end
