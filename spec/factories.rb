# By using the symbol ':user', we get Factory Girl to simulate the User model.
Factory.define :user do |user|
	user.name                  "Michael Durfee"
	user.email                 "mdurfee@example.com"
	user.password              "foobar"
	user.password_confirmation "foobar"
end

Factory.sequence :email do |n|
	"Person_#{n}@example.com"
end

Factory.sequence :name do |n|
	"Person #{n}"
end
