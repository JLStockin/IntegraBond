#####################################################################################
#
#
module Contracts; end

require 'state_machine'
require File.dirname(__FILE__) + '/goal_accept_offer'
require File.dirname(__FILE__) + '/goal_reject_offer'
require File.dirname(__FILE__) + '/goal_cancel_offer'

module Contracts::Bet

	class GoalCreateSecondParty < Goal

		#########################################################################
		#
		# The first party is authoring a tranzaction.  Goal is locate a second 
		# Party.
		#
		#########################################################################

		ARTIFACT = :OfferArtifact
		EXPIRE_ARTIFACT = nil
		CHILDREN = [:GoalCancelOffer, :GoalAcceptOffer, :GoalRejectOffer]
		FAVORITE_CHILD = true
		STEPCHILDREN = []
		AVAILABLE_TO = [:Party1]
		DESCRIPTION = "Create an offer"

		def execute()
			unless create_second_party().nil?
				self.machine_state = :s_provisioning
				self.save!
				self.start
			create_n_reserve_first_partys_bet()
			create_n_reserve_first_partys_fees()
			true
		end

		def reverse_execution()
			p1_fees = self.tranzaction.model_instance(:Party1Fees)
			p1_fees.release
			p1_bet = self.tranzaction.model_instance(:Party1Bet)
			p1_bet.release
		end

		def on_expire()
			msg = "\n\nOffer creation timed out." 
			Rails.logger.info(msg)

			# This case is unique, since it's the first Goal.  We want no trace of
			# the transaction left.
			self.tranzaction.destroy()
			true
		end

		#
		# Possibilities:
		# - published offer.  2nd party, type PublishedContact, will identify themselves
		# - existing user will be located by type (EmailContact, SMSContact)
		# - new user.  No user found, try to contact her
		#
		def create_second_party()
			p2 = self.tranzaction.party2

			if p2.nil? then
				contact = nil

				# PublishedContact?
				if artifact.party2_contact_type == PublishedContact.to_s then
					contact = PublishedContact.create(
						self.artifact.party2_contact_type,
						self.artifact.party2_contact_data
					)
				# Existing User?
				else
					contacts = Contact.lookup(\
						artifact.party2_contact_type,
						artifact.party2_contact_data\
					)
					# TODO: create a GoalResolveContactList to let user select if multiple results
					contact = contacts[0] unless (contacts.nil?)

					# If we failed to find a User, then create the right type of Contact
					# and attempt to contact the non-User
					if contact.nil? then
						contact = self.namespaced_class(\
							artifact.party2_contact_type.camelize.to_sym\
						).new()
						contact.contact_data = artifact.party2_contact_data
						contact.save!
					end
				end

				p2 = self.tranzaction.namespaced_class(:Party2).new(\
					contact_id: contact.id,
					tranzaction_id: self.tranzaction_id
				)
				p2.save!
			end
			return p2
		end

		def create_n_reserve_first_partys_bet()
			p1_bet = self.tranzaction.party1_bet
			if p1_bet.nil? then
				p1_bet = self.tranzaction.namespaced_class(:Party1Bet).new()
				p1_bet.tranzaction_id = self.tranzaction.id
				p1_bet.value = artifact.bet_cents
				p1_bet.origin = self.tranzaction.party1 
				p1_bet.disposition = p1_bet.origin 
				p1_bet.save!
			end
			p1_bet.reserve
		end

		def create_n_reserve_first_partys_fees()
			p1_fees = self.tranzaction.party1_fees
			if p1_fees.nil? then
				p1_fees = self.tranzaction.namespaced_class(:Party1Fees).new()
				p1_fees.tranzaction_id = self.tranzaction.id
				p1_fees.value = self.tranzaction.fees()
				p1_fees.origin = self.tranzaction.party1 
				p1_fees.disposition = p1_fees.origin 
				p1_fees.save!
			end
			p1_fees.reserve
		end

	end

	class OfferArtifact < Artifact
		PARAMS = { \
			bet_cents: Contracts::Bet::ContractBet.bond_for( :Party1 ),
			party1_contact_id: '0',
			party2_contact_type: 'email', party2_contact_data: 'JoeBlow@example.com',
			expirations: {\
				GoalTenderOffer:			[ nil,
					"lambda {DateTime.now.advance(seconds: 30)}" ],

				GoalCancelOffer:			:never,

				GoalAcceptOffer:			[ :GoalTenderOffer,
					"lambda {|g| g.advance(seconds: 10)}" ],

				GoalRejectOffer:			:never,

				GoalDeclareWinner:			[ :GoalAcceptOffer,
					"lambda {|g| g.advance(hours: 48)}" ],

				GoalMutualCancellation:		:never	
			}\
		}

	end

	class UserNotFoundArtifact < Artifact
	end

end
