###################################################################################
#
# Transaction and supporting infrastructure.
#
# Instantiations of contracts are actually transactions.
#
# Transactions inherit from this class and must implement all the constants
# referenced below.  Consider this class abstract.
#

class Transaction < ActiveRecord::Base

	#
	# Constants
	#
	CONTRACT_DIRECTORY = "app/models/contracts"
	CONTRACT_NAMESPACE = "IBContracts"

	#
	# Code to recognize contracts found in app/models/contracts follows
	#
	class << self 
		attr_accessor :contracts
	end
	Transaction.contracts = []

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

	include ActiveModel::Validations

	attr_accessor :role_of_origin, :milestones
	attr_reader :type

	# Associations
	belongs_to	:author, :class_name => :User
	has_one		:prior_transaction, :class_name => :Transaction
	has_many	:parties, class_name: :Party 
	has_many	:valuables
	has_many	:evidences	# [sic.  ActiveRecord hassles.]

	# Custom (yaml) DB formats
	serialize	:milestones, Hash
	serialize	:fault, Hash

	# Validations
	validates	:milestones, :machine_state, :role_of_origin, :type, :fault, :presence => true
	validates_with TransactionValidator  

	# !!!!!!!! TODO: Add validation for machine state: ask machine for all states
#	validates_associated


	# Populate fields with defaults for new records
	class TransactionARWrapper
		def after_initialize(record)
			record.send(:set_defaults)	# bypass private
		end

		def after_create(record)
			record.send(:set_defaults)	# bypass private
		end

		def before_save(record)
			# bypass private
		end
	end

	after_initialize	TransactionARWrapper.new	
	after_create		TransactionARWrapper.new	
	before_save			TransactionARWrapper.new	

	########################################################################################
	#
	# Utilities
	#

	# Constants that must be defined in the contract (sublclass of Transaction), and
	# the test to make sure this happened
	#
	ContractConstantNames = %W/ROLES XASSETS VERSION TAGS AUTHOR_EMAIL ROLES CONTRACT_NAME SUMMARY/

	def contract_constants_defined?()
		bad_constant = ""
		ContractConstantNames.each do |constant_name|
			bad_constant = constant_name
			Module.const_get(constant_name)
		end
		return true
	rescue RuntimeError, NameError => error 
		raise "#{self.class.to_s}: undefined constant #{bad_constant}"
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

	private

		def set_defaults
			return if self.class == Transaction

			self.milestones ||= self.class::INITIAL_MILESTONES
			self.machine_state ||= self.class::INITIAL_MACHINE_STATE
			self.fault ||= self.class::INITIAL_FAULT
			self.type ||= self.class.to_s
		end

		def Transaction.valid_constant?(name)
			name = name.split("::")
			return false if name.length < 2
			name = name[-1]
			Module.const_get(Transaction::CONTRACT_NAMESPACE).const_get(name)
			return true
		rescue NameError
			false
		end
end
