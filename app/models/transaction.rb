################################################################################
#
# Functionally, this is an abstract Transaction class to support Rails single table
# inheritance (STI).
# Be sure to include the TransactionInstance Module in your derived class.
#
require 'state_machine'

class Transaction < ActiveRecord::Base

	#
	# ActiveRecord setup
	#
	include ActiveModel::Validations

	attr_accessor :role_of_origin, :milestones, :contract_params

	attr_reader :type

	# Associations
	belongs_to	:author, :class_name => :User
	has_one		:prior_transaction, :class_name => :Transaction
	has_many	:parties, class_name: :Party 
	has_many	:valuables
	has_many	:evidences	# [sigh.  ActiveRecord.]
	has_many	:disputes

	# Custom (yaml) DB formats
	serialize	:milestones, Hash
	serialize	:contract_data, Hash

	#
	# Callbacks and helper classes
	#
	# Populate fields with defaults for new records
	class TransactionARValidator
		def after_initialize(record)
			record.send(:set_defaults)	# bypass private
		end

		def before_create(record)
			record.send(:set_defaults)	# bypass private
		end

		def before_save(record)
			# bypass private
		end
	end

	#
	# Validations for Transaction.rb, an abstract base for contracts used in all Transactions
	#
	class TransactionValidator < ActiveModel::Validator
		def validate(record)
			record.errors[:role_of_origin] << "is not a valid role in this contract" \
				unless record.roles.include? role_of_origin
	
			if ENV["RAILS_ENV"] == "test" then
				record.errors[:author_email] << "doesn't look like a valid email address" \
					unless !(record.author_email =~ User::EMAIL_REGEX).nil?
			else
				# TODO: put proper email address validation here
			end
		end
	end

	# Validations
	validates		:milestones, :presence => true
	validates		:machine_state, :presence => true
	validates		:type, :presence => true
	validates		:contract_data, :presence => true
	validates_with	TransactionValidator  

	# !!!!!!!! TODO: Add validation for machine state: ask machine for all states
	#validates_associated
	#saves_associated

	after_initialize	TransactionARValidator.new	
	after_create		TransactionARValidator.new	
	before_save			TransactionARValidator.new	

	#######################################################################
	#
	# Constants
	#
	CONTRACT_DIRECTORY = "app/models/contracts"
	CONTRACT_NAMESPACE = "IBContracts"

	#
	# Temporary implementation.  Ultimately, we might have a fee schedule table
	# Right now, just associate each known transaction class with a transaction fee.
	#
	FEES = Hash.new
	FEES["Default"]		= "$2.00"
	FEES["CLPurchase"]	= "$2.00"

	DEFAULT_BOND = "$20"

	#
	# Constants that must be defined in the contract (subclass of Transaction), and
	# the test to make sure this happened
	#
	ContractConstantNames = %W/ROLES XASSETS VERSION TAGS AUTHOR_EMAIL CONTRACT_NAME SUMMARY/

	#
	# Code to find and register contracts found in app/models/contracts
	#
	class << self 
		attr_accessor :contracts
	end
	self.contracts = []

	# This callback watches for creation of subclasses of Transaction and registers them
	def Transaction.inherited(contract)
		self.contracts << contract
	end

	def Transaction.load_contracts
		Dir[Rails.root.join(Transaction::CONTRACT_DIRECTORY).join("*.rb")].each do |f|
			require f
		end
	end
	Transaction.load_contracts()

	########################################################################################
	#
	# Class-level Utilities for Transactions
	#
	def Transaction.contract_constants_defined?()
		bad_constant = ""
		begin	
			ContractConstantNames.each do |constant_name|
				bad_constant = constant_name
				Module.const_get(constant_name)
			end
			return true
		rescue RuntimeError, NameError => error 
			raise "#{self.class.to_s}: undefined constant #{bad_constant}"
		end
	end

	def Transaction.roles
		self.class::ROLES.keys # Must be provided by subclass
	end

	def Transaction.has_role?(role)
		self.class::ROLES.key?(role) ? true : false
	end

	def Transaction.role_name(role)
		self.class::ROLE_NAMES[role]
	end

	def Transaction.xassets
		self.class::XASSETS # Must be provided by subclass
	end

	def Transaction.xasset?(xasset)
		self.class::XASSETS.key?(xasset) ? true : false
	end

	def Transaction.version
		self.class::VERSION
	end

	def Transaction.summary 
		self.class::SUMMARY
	end

	def Transaction.contains_tag?(tag)
		return self.class::TAGS.downcase.include?(tag.downcase)
	end

	def Transaction.author
		User.find_by_email(:email => self.class::AUTHOR_EMAIL)
	end

	def Transaction.contract_name
		self.class::CONTRACT_NAME
	end

	def Transaction.valid_contract_type?(class_name)
		valid_constant?(class_name) and \
			Transaction.contracts.include?(Object.class_eval(class_name))	
	end

end
