class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  # def after_sign_in_path_for(resource)
  #   app_dashboard_index_path
  # end
end
