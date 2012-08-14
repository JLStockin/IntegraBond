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
# Users
#
admin = User.create(first_name: "admin", last_name: "Administrator",
		email: "cschille@gmail.com", password: "foobar")
admin.admin = 1
admin.do_account
admin.save

###################################################################################
#
# Accounts 
#
admin_account = Account.create(name: "admin")

user_data = [[first_name: "Chris", last_name: "Schille", email: "user1@example.com", \
		password: "foobar"], 
	[first_name: "Sali", last_name: "Schille", email: "user2@example.com", \
		password: "foobar"]]

user_data.each do |attrs|
	user = User.create(attrs)
	user.do_account
	user.save
end
