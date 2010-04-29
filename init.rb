require "action_view"
require File.expand_path("../lib/trusted_params_action_view_hooks", __FILE__)

require "action_controller"
ActionController::Base.before_filter do |controller|
  TrustedParams.inject_trusted_params(controller.params)
end
