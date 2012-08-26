require 'spec_helper'

#
# Class-level validations for Contracts (validations on superclass Contract)
#
describe Contract do

	contract = Contract.contracts[0].to_s

	it "should have found contract(s)" do
		contract.should_not be_nil
	end

	it "returns true for valid_contract_type? with a valid contract" do
		Transaction.valid_contract_type?(contract).should be_true
	end

	it "returns false for valid_contract_type? for an invalid contract" do
		Transaction.valid_contract_type?("CrudCrudCrud").should be_false
	end

	describe ": class methods for contracts" do

		@contracts = Transaction.contracts

		@contracts.each.should do |contract|

			it "should create a new instance given valid attributes" do
				@transaction = new_test_transaction(class_name)
				@transaction.save!
			end

			it "should not create a new instance given invalid attributes" do
				@transaction = new_invalid_test_transaction(class_name)
				@transaction.should_not be_valid
			end
		end	

		@contracts.each.should do |contract|

			before(:each) do
				@contract = contract
				@contract_name = contract.to_s
				@transaction = new_test_transaction(contract_name)
				@transaction.roles.each do |role_sym|
					role_factory_name = role_sym.to_s + "_party"
					party = FactoryGirl.create(role_sym)
				end
			end

			it "should pass basic class validations" do
				contract.validate_contract
			end

			it "should have a name" do
				@transaction.should respond_to(:name)
				@transaction.name.should_not be_nil
			end

			it "should have a summary" do
				@transaction.should respond_to(:summary)
			end

			it "should have an a valid email address for author" do
				@transaction.should respond_to(:author_email)
			end

			it "should respond to user_exists?" do
				@transaction.should respond_to(:user_exists?)
			end

			it "should have tags" do
				@transaction.should respond_to(:tags)
			end

			it "should be able to locate a valid tag" do
				@transaction.contains_tag?(:default).should_not be_nil
			end

			it "should be unable to locate an invalid tag" do
				@transaction.contains_tag?(:bunga).should be_nil
			end

			it "should have a type (for ActiveRecord)" do
				@transaction = new_test_transaction(class_name, @attr)
				@transaction.should respond_to(:type)
			end

			it "should have at least one role" do
				Transaction.should respond_to(:roles)
				Transaction.roles.count.should > 0
			end

			it "should be able to give a role name for a role" do
				Transaction.should respond_to(:role_name)
				role = Transaction.roles.keys[0]
				Transaction.role_name(role).should \
					== Transaction.roles[Transaction.roles.keys[0] ]
			end

			it "should be able to identify a valid role" do
				Transaction.should respond_to(:valid_role?)
				role = Transaction.roles.keys[0]
				Transaction.valid_role?(role).should be_true
			end

			it "should be able to identify an invalid role" do
				Transaction.valid_role?(:bottom_fisherman).should be_false
			end

			it "contract should have 0 or more transaction assets (xassets)" do
				Transaction.should respond_to(:xassets)
			end

			it "should identify a good transaction asset (xasset)" do
				test_for_valid_xasset().should be_true
			end
				
			it "should identify a bad transaction asset (xasset)" do
				Transaction.xasset?(:dead_skunks).should be_false
			end

			it "should have an initial artifact" do
				pending
			end

			it "should have an initial goal" do
				pending
			end

		end	
	end
end
