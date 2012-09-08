require 'spec_helper'

class Transaction < ActiveRecord::Base

end

class ArtifactTest < Artifact
	attr_accessor :transaction, :sender, :receiver
end

describe Artifact do
	before(:each) do
		party1 = FactoryGirl.build(:party1)
		party2 = FactoryGirl.build(:party2)
		transaction = Transaction.new
		@artifact = ArtifactTest.new
		@artifact.transaction = transaction 
	end

	it "should create a new instance given valid attributes" do
		@artifact.save!
	end

end
