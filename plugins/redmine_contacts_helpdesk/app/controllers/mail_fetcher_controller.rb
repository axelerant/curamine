class MailFetcherController < ApplicationController
  unloadable
  require 'timeout'

  before_filter :check_credential

  def receive_imap
      imap_options = {:host => params['host'],
                      :port => params['port'],
                      :ssl => params['ssl'],
                      :username => params['username'],
                      :password => params['password'],
                      :folder => params['folder'],
                      :move_on_success => params['move_on_success'],
                      :move_on_failure => params['move_on_failure']}

      options = { :issue => {} }
      %w(project status tracker category priority).each { |a| options[:issue][a.to_sym] = params[a] if params[a] }
      options[:allow_override] = params['allow_override'] if params['allow_override']
      options[:unknown_user] = params['unknown_user'] if params['unknown_user']
      options[:no_permission_check] = params['no_permission_check'] if params['no_permission_check']

    begin
      Timeout::timeout(15){ Redmine::IMAP.check(imap_options, options) }
    rescue Exception => e
      @error_messages = [e.message]
    end


    if @error_messages.blank?
      respond_to do |format|
        format.html { render :nothing => true, :status => :ok }
        format.api { render_api_ok }
      end    
    else
      respond_to do |format|
        format.html { render :text => @error_messages, :status => :unprocessable_entity, :layout => nil }
        format.api { render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil}
      end    
    end
    
  end

  def receive_pop3
    pop_options  = {:host => params['host'],
                    :port => params['port'],
                    :apop => params['apop'],
                    :username => params['username'],
                    :password => params['password'],
                    :delete_unprocessed => params['delete_unprocessed']}

    options = { :issue => {} }
    %w(project status tracker category priority).each { |a| options[:issue][a.to_sym] = params[a] if params[a] }
    options[:allow_override] = params['allow_override'] if params['allow_override']
    options[:unknown_user] = params['unknown_user'] if params['unknown_user']
    options[:no_permission_check] = params['no_permission_check'] if params['no_permission_check']

    begin
      Timeout::timeout(15){ Redmine::POP3.check(pop_options, options) }
    rescue Exception => e
      @error_messages = [e.message]
    end


    if @error_messages.blank?
      respond_to do |format|
        format.html { render :nothing => true, :status => :ok }
        format.api { render_api_ok }
      end    
    else
      respond_to do |format|
        format.html { render :text => @error_messages, :status => :unprocessable_entity, :layout => nil }
        format.api { render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil}
      end    
    end
    

  end

  private

  def check_credential
    User.current = nil
    unless Setting.mail_handler_api_enabled? && params[:key].to_s == Setting.mail_handler_api_key
      render :text => 'Access denied. Incoming emails WS is disabled or key is invalid.', :status => 403
    end
  end  

end
