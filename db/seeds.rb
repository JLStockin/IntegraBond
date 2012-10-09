# This file should contain all the record creation needed to seed the database with its
# default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

###################################################################################
#
# Administrator and dummy in first slot 
#

fraud_narc = User.create(	first_name: "Fraud", last_name: "Narc", \
							email: "bungabunga@example.com",
							phone: "408-555-1000",
							password: "foobar",
							use_phone_as_primary: false)
fraud_narc.save

admin = User.create(	first_name: "M", last_name: "Administrator",
						email: "cschille@gmail.com",
						phone: "408-555-1001",	
						password: "foobar",
						use_phone_as_primary: false)
admin.admin = 1
admin.monetize("admin")
admin.save

# Two users
user_data = [ \
				{
					first_name: "Chris", last_name: "Schille",
					email: "user1@example.com",
					phone: "408-555-1002",
					password: "foobar",
					use_phone_as_primary: true,
				}, 
				{
					first_name: "Sali", last_name: "Schille",
					email: "user2@example.com",
					phone: "408-555-1003",
					password: "foobar",
					use_phone_as_primary: false
				}
			]

user_data.each do |attrs|
	user = User.create(attrs)
	user.monetize()
	user.account.set_funds("$1000", 0)
	user.save
end
