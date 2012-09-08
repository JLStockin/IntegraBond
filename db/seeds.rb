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
# Administrator 
#

fraud_narc = User.create(	first_name: "Fraud", last_name: "Narc", \
							email: "bungabunga@example.com", password: "foobar")
fraud_narc.save

admin = User.create(first_name: "M", last_name: "Administrator",
		email: "cschille@gmail.com", password: "foobar")
admin.admin = 1
admin.monetize("admin")
admin.save

# Two users
user_data = [ \
				{first_name: "Chris", last_name: "Schille", email: "user1@example.com", \
					password: "foobar"}, 
				{first_name: "Sali", last_name: "Schille", email: "user2@example.com", \
					password: "foobar"} \
			]

user_data.each do |attrs|
	user = User.create(attrs)
	user.monetize()
	user.save
end
