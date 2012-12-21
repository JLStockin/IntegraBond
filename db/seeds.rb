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
# Administrator and dummy in first slots 
#
require 'contact'

user_data = [ \
				{	first_name: "Fraud", last_name: "Narc",
					password: "foobar",
					email: "bungabunga@example.com",
					sms: "408-555-1000"
				},
				{	first_name: "M", last_name: "Administrator",
					password: "foobar",
					email: "cschille@example.com",
					sms: "408-555-1001"
				},
				{
					first_name: "Chris", last_name: "Schille",
					password: "foobar",
					email: "user1@example.com",
					sms: "408-555-1002"
				}, 
				{
					first_name: "Sali", last_name: "Schille",
					password: "foobar",
					email: "user2@example.com",
					sms: "408-555-1003"
				}
			]

user_data.each do |attrs|
	user = User.new()
	user.first_name = attrs[:first_name]
	user.last_name = attrs[:last_name]
	user.password = attrs[:password]
	user.username = attrs[:email]
	user.admin = 1 if user.last_name == "Administrator"
	user.save!

	email = EmailContact.new()
	email.data = attrs[:email]
	email.user = user
	email.save!

	sms = SMSContact.new()
	sms.data = attrs[:sms]
	sms.user = user
	sms.save!

	user.monetize("default")
	user.account.set_funds("$1000", 0)
	user.account.save!
end
