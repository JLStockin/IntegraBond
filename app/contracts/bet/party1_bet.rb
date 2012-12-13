module Contracts::Bet
	BET = "$20"
	FEES = "$2"
	class Party1Bet		< Valuable
		VALUE = Money.parse(BET) 
		OWNER = :Party1
		ASSET = false
	end
	class Party1Fees	< Valuable
		VALUE = Money.parse(FEES) 
		OWNER = :Party1
		ASSET = false
	end
	class Party2Bet		< Valuable
		VALUE = Money.parse(BET) 
		OWNER = :Party2
		ASSET = false
	end
	class Party2Fees	< Valuable
		VALUE = Money.parse(FEES) 
		OWNER = :Party2
		ASSET = false
	end
end
