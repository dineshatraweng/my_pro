class DocAdminInstructionsController < ApplicationController
  layout(nil)
  def index
    if current_user_is_admin?
      send_file "#{Rails.root}/public/images/admin_instructions/Staging_Documents_on_Doc_Site.pdf",  :type => 'application/pdf', :disposition => "inline", :status => :ok
    else
      redirect_to root_path
    end
  end
end
