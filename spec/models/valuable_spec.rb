require 'spec_helper'

shared_examples_for "any valuable class" do

	it "should have the right constants" do
		@klass.verify_constants().should be_true
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
		@valuable.origin.contact.user.account.available_funds.should be \
			== Money.parse(INITIAL_BALANCE)
		@valuable.machine_state_name.should be == :s_initial
	end
end

describe Valuable do

	describe "that's not an asset" do

		before(:each) do
			@klass = Contracts::Bet::Valuable1 
			@tranz = prepare_test_tranzaction(Contracts::Bet::TestContract)
			@valuable = @klass.new()
			@valuable.tranzaction = @tranz
			@valuable.value = VALUABLE_VALUE 
			@valuable.origin = @tranz.p_party1 
			@valuable.disposition = @tranz.p_party1 
			@valuable.save!
		end

		it_behaves_like "any valuable class"
		it_behaves_like "any valuable"

		describe "reserved" do

			before(:each) do
				@valuable.reserve()
			end

			it "should cause transition to :s_reserved" do
				@valuable.machine_state_name.should be == :s_reserved
			end

			it "should cause party1's funds to be reserved" do
				@valuable.origin.contact.user.account.available_funds.should \
					be == INITIAL_BALANCE - VALUABLE_VALUE
			end
		end

		describe "transferred" do

			before(:each) do
				resolve_party(@tranz, :PParty2)
				@valuable.reserve()
				@valuable.disposition = @valuable.tranzaction.p_party2
				@valuable.transfer()
			end

			it "should transition to :s_transferred" do 
				@valuable.machine_state_name.should be == :s_transferred
			end

			it "should cause party1's funds to be transferred to party2" do
				@valuable.origin.contact.user.account.available_funds.should be \
					== INITIAL_BALANCE - VALUABLE_VALUE 
				@valuable.disposition.contact.user.account.available_funds.should be \
					== INITIAL_BALANCE + VALUABLE_VALUE
			end
		end

		describe "disputed" do
			before(:each) do
				resolve_party(@tranz, :PParty2)
				@valuable.reserve()
				@valuable.disposition = @valuable.tranzaction.p_party2
				@valuable.transfer()
				@valuable.dispute()
			end

			it "should put valuable in a state of dispute" do 
				@valuable.machine_state_name.should be == :s_reserved_4_dispute
			end

			it "should place a hold on defendant's (second party's) funds" do
				@valuable.origin.contact.user.account.available_funds.should be \
					== INITIAL_BALANCE - VALUABLE_VALUE
				@valuable.origin.contact.user.account.total_funds.should be \
					== INITIAL_BALANCE - VALUABLE_VALUE
				@valuable.disposition.contact.user.account.available_funds.should be \
					== Money.parse(INITIAL_BALANCE)
				@valuable.disposition.contact.user.account.total_funds.should be \
					== INITIAL_BALANCE + VALUABLE_VALUE
			end
		end

		describe "adjudication" do
			before(:each) do
				resolve_party(@tranz, :PParty2)
				@valuable.reserve()
				@valuable.disposition = @valuable.tranzaction.p_party2
				@valuable.transfer()
				@valuable.dispute()
			end

			it "prior to, appropriate funds should be reserved in second party's account" do
				@valuable.machine_state_name.should be == :s_reserved_4_dispute
			end

			describe "in first party's favor" do
				before(:each) do
					@valuable.adjudicate(:for_plaintif => true)
				end

				it "should cause the valuable to be transferred back for first party" do
					@valuable.machine_state_name.should be == :s_transferred
				end

				it "should restore previously transferred funds to first party" do
					@valuable.origin.contact.user.account.available_funds.should be \
						== INITIAL_BALANCE
					@valuable.origin.contact.user.account.total_funds.should be \
						== INITIAL_BALANCE
				end

				it "should remove hold on second party's funds" do
					@valuable.disposition.contact.user.account.available_funds.should be \
						== INITIAL_BALANCE
				end

				it "should withdraw previously reserved funds from second party" do
					@valuable.disposition.contact.user.account.total_funds.should be \
						== INITIAL_BALANCE
				end
			end

			describe "in second party's favor" do
				before(:each) do
					@valuable.adjudicate(:for_plaintif => false)
				end

				it "should cause the valuable to remain w/ second party" do
					@valuable.machine_state_name.should be == :s_transferred
				end

				it "should not restore previously transferred funds to first party" do
					@valuable.origin.contact.user.account.available_funds.should be \
						== INITIAL_BALANCE - VALUABLE_VALUE
					@valuable.origin.contact.user.account.total_funds.should be \
						== INITIAL_BALANCE - VALUABLE_VALUE
				end

				it "should leave previously transferred funds with second party" do
					@valuable.disposition.contact.user.account.total_funds.should be \
						== INITIAL_BALANCE + VALUABLE_VALUE
				end

				it "should release hold on second party's funds" do
					@valuable.disposition.contact.user.account.available_funds.should be \
						== INITIAL_BALANCE + VALUABLE_VALUE
				end
			end

		end
	end

	describe "that is an asset" do

		before(:each) do
			@klass = Contracts::Bet::Valuable2 
			@tranz = prepare_test_tranzaction(Contracts::Bet::TestContract)
			resolve_party(@tranz, :PParty2)
			@valuable = @klass.new()
			@valuable.tranzaction = @tranz
			@valuable.value = VALUABLE_VALUE 
			@valuable.origin = @tranz.p_party1 
			@valuable.disposition = @tranz.p_party1 
			@valuable.save!
		end

		it_behaves_like "any valuable class"
		it_behaves_like "any valuable"

		it "should transition to :s_reserved when it receives a :reserve; party1's " \
				+ "funds should not be reserved" do
			@valuable.reserve()
			@valuable.machine_state_name.should be == :s_reserved
			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
		end

		it "should transition to :s_transferred when it receives a :transfer; party1's " \
				+ "funds should not be transferred to party2" do
			@valuable.reserve()
			@valuable.disposition = @valuable.tranzaction.p_party2
			@valuable.transfer()
			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.machine_state_name.should be == :s_transferred
		end

		it "should transition to :s_reserved when it receives a :dispute; " \
				+ "there shouldn't be a hold on party2's funds" do
			@valuable.reserve()
			@valuable.disposition = @valuable.tranzaction.p_party2
			@valuable.transfer()
			@valuable.dispute()

			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.origin.contact.user.account.total_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.disposition.contact.user.account.total_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.machine_state_name.should be == :s_reserved_4_dispute
		end

		it "should give party1 the valuable if ruling " \
				+ "is in party1's favor (:adjudicate event)" do
			@valuable.reserve()
			@valuable.disposition = @valuable.tranzaction.p_party2
			@valuable.transfer()
			@valuable.dispute()
			@valuable.adjudicate(:for_plaintif => true)

			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.origin.contact.user.account.total_funds.should be == \
				Money.parse(INITIAL_BALANCE)
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.disposition.contact.user.account.total_funds.should be == \
				Money.parse(INITIAL_BALANCE)
			@valuable.machine_state_name.should be == :s_transferred
		end

		it "should be no hold on party2's funds if ruling " \
				+ "is in party2's favor (:adjudicate event)" do
			@valuable.reserve()
			@valuable.disposition = @valuable.tranzaction.p_party2
			@valuable.transfer()
			@valuable.dispute()
			@valuable.adjudicate(:for_plaintif => false)

			@valuable.origin.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.origin.contact.user.account.total_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.disposition.contact.user.account.available_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.disposition.contact.user.account.total_funds.should be \
				== Money.parse(INITIAL_BALANCE)
			@valuable.machine_state_name.should be == :s_transferred
		end
	end
end
