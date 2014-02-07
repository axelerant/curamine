class HelpdeskMailerController < ActionController::Base
  unloadable
  before_filter :check_credential
  
  # Submits an incoming email to ContactsMailer
  def index
    options = params.dup
    email = options.delete(:email)
    if HelpdeskMailer.receive(email, options)
      render :nothing => true, :status => :created
    else
      render :nothing => true, :status => :unprocessable_entity
    end
  end

  def get_mail
    msg_count = 0
    errors = []
    Project.active.has_module(:contacts_helpdesk).each do |project|
      begin
        msg_count += HelpdeskMailer.check_project(project.id)  
      rescue Exception => e
        errors << e.message
      end

    end
    
    render :status => :ok,  :text => {:count => msg_count, :errors => errors}.to_json

  end

  private

  def check_credential
    User.current = nil
    unless Setting.mail_handler_api_enabled? && params[:key].to_s == Setting.mail_handler_api_key
      render :text => 'Access denied. Incoming emails WS is disabled or key is invalid.', :status => 403
    end
  end
end
