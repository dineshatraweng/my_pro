# Load the rails application
require File.expand_path('../application', __FILE__)

require File.join(File.dirname(__FILE__), 'app_util')
AppUtil.load_app_config

# Initialize the rails application
Tibcodocs::Application.initialize!

require 'tibcommunity_iframe_login'
include Rails.application.routes.url_helpers
