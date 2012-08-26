require 'spec_helper'

class Transaction < ActiveRecord

end

class ArtifactTest < Artifact
	attr_accessor :transaction, :sender, :receiver
end

describe Artifact do
	before(:each) do
		party1 = FactoryGirl.build(:party_seller)
		party2 = FactoryGirl.build(:party_buyer)
		transaction = Transaction.new
		@artifact = ArtifactTest.new
		@artifact.sender = party1
		@artifact.receiver = party2
		@artifact.transaction = transaction 
	end

	it "should create a new instance given valid attributes" do
		@artifact.save!
	end

end
