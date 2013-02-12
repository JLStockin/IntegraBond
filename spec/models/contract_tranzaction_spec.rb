require 'spec_helper'

describe "Tranzaction" do

	it "should create a Tranzaction" do
		create_user(:admin_user)
		klass = Contracts::Bet::ContractBet
		user1 = create_user(:seller_user)
		tranz	= Contract.create_tranzaction(klass, user1)
	end

	it "should destroy and cleanup after a Tranzaction" do
		create_user(:admin_user)
		klass = Contracts::Bet::ContractBet
		user1 = create_user(:seller_user)
		tranz	= Contract.create_tranzaction(klass, user1)
		tranz.destroy()
		Contract.all.count.should be 0
		Party.all.count.should be 0
		Valuable.all.count.should be 0
		Goal.all.count.should be 0
		Artifact.all.count.should be 0
	end

	describe "association accessor" do
		before(:each) do
			create_user(:admin_user)
			user1 = create_user(:seller_user)

			klass = Contracts::Bet::TestContract
			@tranz = Contract.create_tranzaction(klass, user1)
			@artifact = Contracts::Bet::TestArtifact.new()
			@tranz.artifacts << @artifact
		end

		it "should read association values correctly" do
			@tranz.test_artifact.a.should be == :no
			@tranz.test_artifact.b.should be == "hello"	
			@tranz.test_artifact.c.should be == 12
			@tranz.test_artifact.value.should be == Money.parse("$11") 
			
		end

		describe "should write" do

			it "boolean association values correctly" do
				@tranz.test_artifact.a = :yes
				@tranz.test_artifact.a.should be == :yes
			end

			it "string association values correctly" do
				@tranz.test_artifact.b = "howdy" 
				@tranz.test_artifact.b.should be ==  "howdy"
			end

			it "integer association values correctly" do
				@tranz.test_artifact.c = 100
				@tranz.test_artifact.c.should be == 100
			end

			it "money association values correctly" do
				@tranz.test_artifact.value = 100
				@tranz.test_artifact.value.should be == 100
			end

		end

		describe "should save" do

			it "boolean association values correctly" do
				@tranz.test_artifact.a = :yes
				@tranz.test_artifact.save!
				@tranz.test_artifact.reload
				@tranz.test_artifact.a.should be == :yes
			end

			it "string association values correctly" do
				@tranz.test_artifact.b = "howdy" 
				@tranz.test_artifact.save!
				@tranz.test_artifact.reload
				@tranz.test_artifact.b.should be ==  "howdy"
			end

			it "integer association values correctly" do
				@tranz.test_artifact.c = 100
				@tranz.test_artifact.save!
				@tranz.test_artifact.reload
				@tranz.test_artifact.c.should be == 100
			end

			it "money association values correctly" do
				@tranz.test_artifact.value = 100
				@tranz.test_artifact.save!
				@tranz.test_artifact.reload
				@tranz.test_artifact.value.should be == 100
			end
		end

	end

	shared_examples_for "Party" do
		it "party shouldn't be nil" do
			party.should_not be_nil
		end

		it "party should have a Contact" do
			party.contact.should_not be_nil
		end
	end

	shared_examples_for "Valuable" do
		it "should exist" do
			valuable_params[:valuable].should_not be_nil
		end

		it "should have the right amount" do
			valuable_params[:valuable].value.should be == valuable_params[:value]
		end

		it "should have the right origin" do
			valuable_params[:valuable].origin.should be == valuable_params[:origin]
		end

		it "should have the right disposition" do
			valuable_params[:valuable].disposition.should be == valuable_params[:disposition]
		end
	end
		
	describe "parties" do

		it "should be a method on Contract" do
			@tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
			@tranz.should respond_to :parties
		end

		it_should_behave_like "Party" do
			let(:party) {
				tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
				party = tranz.party1()
			}
		end

		it_should_behave_like "Party" do
			let(:party) {
				tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
				party = resolve_party(tranz, :Party2)
			}
		end

		it_should_behave_like "Party" do
			let(:party) {
				tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
				tranz.seed_tranzaction()
				party = tranz.admin_party()
			}
		end

		it "shouldn't find bad parties" do
			expect { 
				tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
				tranz.party3
			}.to raise_error 
		end

	end

	describe "valuables" do
		it "should be a method on Contract" do
			@tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
			@tranz.should respond_to :valuables
		end

		it_should_behave_like "Valuable" do
			let(:valuable_params) {
				tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
				valuable = tranz.party1_bet()
				value = Money.parse("$20")
				origin = tranz.party1
				disposition = origin 
				{
					tranz: tranz,
					valuable: valuable,
					value: value,
					origin: origin,
					disposition: disposition
				}
			}
		end

		it_should_behave_like "Valuable" do
			let(:valuable_params) {
				tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
				valuable = tranz.party2_bet()
				value = Money.parse("$20")
				origin = tranz.party2
				disposition = origin 
				{
					tranz: tranz,
					valuable: valuable,
					value: value,
					origin: origin,
					disposition: disposition
				}
			}
		end

		it_should_behave_like "Valuable" do
			let(:valuable_params) {
				tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
				valuable = tranz.party1_fees()
				value = Money.parse("$2")
				origin = tranz.party1
				disposition = origin 
				{
					tranz: tranz,
					valuable: valuable,
					value: value,
					origin: origin,
					disposition: disposition
				}
			}
		end

		it_should_behave_like "Valuable" do
			let(:valuable_params) {
				tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet);
				valuable = tranz.party2_fees()
				value = Money.parse("$2")
				origin = tranz.party2
				disposition = origin 
				{
					tranz: tranz,
					valuable: valuable,
					value: value,
					origin: origin,
					disposition: disposition
				}
			}
		end
	end

	describe "start" do
		before(:each) do
			@tranz = prepare_test_tranzaction(Contracts::Bet::ContractBet)
		end

		it "should be a method" do
			@tranz.should respond_to(:start)
		end

		it "should create a goal" do
			@tranz.start
			@tranz.goals.first.type.should be == "Contracts::Bet::GoalTenderOffer"
		end

		it "should have associates for a user"

		it "should create Artifacts"

	end

	describe "Goal" do
		it "should have Goals for a user"
		it "should map a Goal to an Artifact (create_artifact_for())"
		it "should provision Goals with Artifacts"
		it "should have Expirations"
		it "should link Goals to Expirations"
	end

	describe "notifications" do
		it "should notify Parties that data has changed"
		it "should flash/notify Parties"
	end

end
