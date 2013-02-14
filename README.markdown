This is IntegraBond, a generalized transaction execution engine written 
in Ruby and for Rails.

What is it?
-----------
IntegraBond offers a domain-specific language for describing Contracts.
Contracts are executable schemas that, when instantiated, become
transactions.  Transactions can be long-running.  These transactions can
manage business activities as diverse as an instance of a subscription to
anti-virus software, or the contracting of a tree-care job with a
homeowner.

Motivation
----------
The motivation for IntegraBond is a recognition that business transactions
share many common elements:

1) they have one or more parties (e.g, a single person could can make
   a new year's resolution/bet with themselves)
1) they're all governed by a contract, either explicitly or implicitly
2) they generally involve the exchange of valuables and the performance
   of certain actions, including showing up, delivery and recording of
   documents, making payments to escrow or to other parties, etc.
3) transactions that fail must be carefully unwound, but not necessarily
   to their original state
4) transactions can involve massively complex state machines

A business is an entity that solicits (and hopefully performs in)
transactions with clients.  IntegraBond, then, is the code to run a
cloud-based, software-as-a-service (SaaS) host for conducting any sort
of business, wherein new businesses are defined by their contracts.

IntegraBond's architecture allows new Contract types to be introduced to
the running server.  Without a migration of the database schema or a
database server reboot, the server supports the instantiation of new
transactions based on the new Contract definition!

State of Affairs
----------------
IntegraBond is a work in progress, now undergoing heavy development by
me, a single developer.

Until 2/14/13, the IntegraBond GitHub repository was private.
After careful consideration, I've made it public as a way of offering
interested parties a way to evaluate my coding style and skills (itself
a sub-goal of wanting to pay my bills.)

Guide to the code
-----------------
The controller logic and views are still fairly rudimentary as of the
above date.  The Contract definition in the

	'app/contracts/bet'

is a primitive sample contract I've been using to guide development.  

Since I haven't yet componentized it for use by others, I'd urge those
browsing the code at this early juncture to look primarily at the
model layer: 

	app/models and
	app/contracts/bet/

Further, you may find looking at IntegraBond's extenstions to
ActiveRecord::Base helpful too:

	/config/initializers/active_record_monkey_patch.rb


A note on terminology
---------------------
Note: due to the heavy overloading of the term 'transaction', IntegraBond
substitutes two invented words for two different ideas:

	A 'Tranzaction' is business affair between one or more parties;
	it's governed by a Contract
	
	An 'Xaction' is an auditable, Account-level movement of funds (a bank
	transaction).

Major areas lacking implementation
----------------------------------
	- mobile client app/browser views
	- server push (to update clients)
	- payment system integration
	- ...

Enjoy, and thanks for your interest!
