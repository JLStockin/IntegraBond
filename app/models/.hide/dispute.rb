
class Dispute < ActiveRecord::Base
	belongs_to	:transaction

	# late, significantly not as described, item not received, payment wrong form,
	# payment not honored
	ALLEGATION_TYPES = [late: " was late", snad: "Item was significantly not as described", \
		inr: "I was prevented from taking the item", pwf: "Wrong form of payment", \
		pnh: "Payment wasn't honored (e.g, bad check)", other: "(Describe)" \
	]
end
