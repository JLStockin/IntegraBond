# Load the rails application
require File.expand_path('../application', __FILE__)

SITE_NAME = "IntegraBond"
PUSH_SERVER = 'http://localhost:9292/faye'
PUSH_SERVER_DRIVER = PUSH_SERVER + '.js'

# Initialize the rails application
IntegraBond::Application.initialize!
