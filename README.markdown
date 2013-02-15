Startup in a Can
----------------

This is IntegraBond, a generalized transaction execution engine written 
in Ruby and for Rails.  Think of it as workflow software specifically 
written to supervise and enforce the execution of business transactions.Alternatively, think of it as a 'startup-in-a-can'.

What is it?
-----------
IntegraBond offers a domain-specific language for describing Contracts.
Contracts are executable schemas that, when instantiated, become
transactions.  Transactions can be long-running.  These transactions can
manage business activities as diverse as an instance of a subscription to
anti-virus software, or the contracting for a tree-care job with a
homeowner.

Motivation
----------
A business is an entity that solicits (and hopefully performs in)
transactions with clients.  IntegraBond, then, is the code to run a
cloud-based, software-as-a-service (SaaS) host for conducting any sort
of business, wherein new businesses are defined by their contracts.

A motivation for IntegraBond is a recognition that business transactions
share many common elements:

1) they have one or more parties (e.g, a single person could can make
   a new year's resolution/bet with themselves)

2) they're all governed by a contract, either explicitly or implicitly

3) they generally involve the exchange of valuables and the performance
   of certain actions, including showing up, delivery and recording of
   documents, making payments to escrow or to other parties, etc.

4) transactions that fail must be carefully unwound, but not necessarily
   to their original state

5) transactions can involve massively complex state machines

IntegraBond's architecture allows new contract types to be introduced to
the running server.  Without a migration of the database schema or a
database server reboot, the server supports the instantiation of new
transactions based on the new Contract definition.  In addition to the
contract definition, additionally, new contracts may require new
user interface (view level) code.

State machines
--------------
It's my belief that a system capable of managing transactions of
any complexity needs a state machine.  However, it's been my experience
that state machines are a terrible way to express or describe the
business rules contained in a contract.

IntegraBond strives to limit itself to a small set of objects that
interact in predictable ways.  This has given rise to several object
types (Ruby classes) that manage their state with their own state
machines.  Yes: in other words, a contract may contain an arbitrary
number of state machines.  A transaction of arbitrary complexity can
be defined and managed through the interaction of relatively simple
building blocks, with the benefit of clarifying business rules.

State of Affairs
----------------
IntegraBond is still a research project, and as such, a work in
progress.  It's now undergoing heavy development by me, a single
developer.

Until 2/14/13, the IntegraBond GitHub repository was private.
After careful consideration, I've made it public as a way of offering
interested parties a way to evaluate my coding style and skills (itself
a sub-goal of wanting to pay my bills.)  At this stage, I would not
recommend trying to use the code.

Guide to the code
-----------------
The controller logic and views are still fairly rudimentary as of the
above date.  The Contract definition in

	'app/contracts/bet'

is a primitive sample contract to develop and verify the engine. 

Since I haven't yet componentized IntegraBond for use by others, I urge
those browsing the code at this early juncture to look primarily at the
model layer: 

	app/models
	app/contracts/bet/

Further, you may find it usefule to look at the extenstions to
ActiveRecord::Base in

	config/initializers/active_record_monkey_patch.rb


A note on terminology
---------------------
Note: due to the heavy overloading of the term 'transaction', IntegraBond
substitutes two invented words for two ideas:

	A 'Tranzaction' is business affair between one or more parties.  It's
	governed by a Contract.
	
	An 'Xaction' is an auditable, Account-level movement of funds; in
	other words, a bank transaction.

Major areas lacking implementation
----------------------------------
	- mobile client app/browser views
	- server push (to update clients)
	- payment system integration
	- invitation system
	- email integration
	- sms integration
	- geodata integration
	- (and much more...) 

Enjoy, and thanks for your interest!
