# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class ContactsController < ApplicationController
  unloadable

  Mime::Type.register "text/x-vcard", :vcf
  Mime::Type.register "application/vnd.ms-excel", :xls

  default_search_scope :contacts

  before_filter :find_contact, :only => [:show, :edit, :update, :destroy]
  before_filter :find_project, :only => [:new, :create]
  before_filter :authorize, :only => [:create, :new]
  before_filter :authorize_contacts, :only => [:edit, :update, :destroy]
  before_filter :find_optional_project, :only => [:index, :contacts_notes, :edit_mails, :send_mails, :bulk_update]

  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy

  helper :attachments
  helper :contacts
  include ContactsHelper
  helper :watchers
  helper :deals
  helper :notes
  helper :custom_fields
  include CustomFieldsHelper
  helper :context_menus unless Redmine::VERSION.to_s < '1.4'
  include WatchersHelper
  helper :sort
  include SortHelper
  helper :queries
  helper :contacts_queries
  include ContactsQueriesHelper
  include NotesHelper

  def index
    retrieve_contacts_query
    sort_init(@query.sort_criteria.empty? ? [['last_name', 'asc'], ['first_name', 'asc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      case params[:format]
      when 'csv', 'pdf', 'xls', 'vcf'
        @limit = Setting.issues_export_limit.to_i
      when 'atom'
        @limit = Setting.feeds_limit.to_i
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
      end
      @contacts_count = @query.contact_count
      @contacts_pages = Paginator.new self, @contacts_count, @limit, params['page']
      @offset ||= @contacts_pages.current.offset
      @contact_count_by_group = @query.contact_count_by_group
      @contacts = @query.contacts(:include => [:projects, :avatar],
                              :search => params[:search],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @filter_tags = @query.filters["tags"] && @query.filters["tags"][:values]

      respond_to do |format|
        format.html do
          unless request.xhr?
            last_notes
            @tags = Contact.available_tags(:project => @project)
          else
            render :partial => contacts_list_style, :layout => false
          end
        end
        format.api
        format.atom { render_feed(@contacts, :title => "#{@project || Setting.app_title}: #{l(:label_contact_plural)}") }
        format.csv { send_data(contacts_to_csv(@contacts), :type => 'text/csv; header=present', :filename => 'contacts.csv') }
        format.xls { send_data(contacts_to_xls(@contacts), :filename => "contacts.xls", :type => 'application/vnd.ms-excel', :disposition => 'attachment') }
        format.vcf { send_data(contacts_to_vcard(@contacts), :filename => "contacts.vcf", :type => 'text/x-vcard', :disposition => 'attachment') }
      end
    else
      respond_to do |format|
        format.html do
          last_notes
          @tags = Contact.available_tags(:project => @project)
          render(:template => 'contacts/index', :layout => !request.xhr?)
        end
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  end

  def show
    scope = @contact.issues
    scope = scope.open unless RedmineContacts.settings[:show_closed_issues]
    @contact_issues_count = scope.visible.count
    @contact_issues = scope.visible.find(:all, :order => "#{Issue.table_name}.status_id, #{Issue.table_name}.updated_on DESC", :limit => 10)
    @deals = @contact.all_visible_deals
    @company_contacts = @contact.company_contacts.visible

    source_id_cond = @contact.is_company ? Contact.visible.order_by_name.select(:id).find_all_by_company(@contact.first_name) << @contact.id : @contact.id
    @note = Note.new(:created_on => Time.now)
    @notes_pages, @notes = paginate :notes,
                                    :per_page => 30,
                                    :conditions => {:source_id  => source_id_cond,
                                                   :source_type => 'Contact'},
                                    :include => [:attachments],
                                    :order => "#{Note.table_name}.created_on DESC"

    respond_to do |format|
      format.js if request.xhr?
      format.html { @contact.viewed }
      format.api
      format.atom { render_feed(@notes, :title => "#{@contact.name || Setting.app_title}: #{l(:label_crm_note_plural)}")  }
      format.vcf { send_data(contact_to_vcard(@contact), :filename => "#{@contact.name}.vcf", :type => 'text/x-vcard;', :disposition => 'attachment') }
    end
  end


  def edit
  end

  def update
    @contact.tags.clear
    if @contact.update_attributes(params[:contact])
      flash[:notice] = l(:notice_successful_update)
      attach_avatar
      respond_to do |format|
        format.html { redirect_to :action => "show", :project_id => params[:project_id], :id => @contact }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render "edit", :project_id => params[:project_id], :id => @contact  }
        format.api  { render_validation_errors(@contact) }
      end
    end
  end

  def destroy
    if @contact.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    respond_to do |format|
      format.html { redirect_back_or_default :action => "index", :project_id => params[:project_id] }
      format.api  { render_api_ok }
    end
  end

  def new
    @duplicates = []
    @contact = Contact.new
    @contact.attributes = params[:contact] if params[:contact] && params[:contact].is_a?(Hash)
  end

  def create
    params[:contact].delete(:project_id)
    @contact = Contact.new(params[:contact])
    @contact.projects << @project
    @contact.author = User.current
    if @contact.save
      flash[:notice] = l(:notice_successful_create)
      attach_avatar
      respond_to do |format|
        format.html { redirect_to (params[:continue] ?  {:action => "new", :project_id => @project} : {:action => "show", :project_id => @project, :id => @contact} )}
        format.js
        format.api  { render :action => 'show', :status => :created, :location => contact_url(@contact) }
      end
    else
      respond_to do |format|
        format.api  { render_validation_errors(@contact) }
        format.js { render :action => "new" }
        format.html { render :action => "new" }
      end
    end
  end

  def contacts_notes
    unless request.xhr?
      @tags = Contact.available_tags(:project => @project)
    end
    # @notes = Comment.find(:all,
    #                            :conditions => { :commented_type => "Contact", :commented_id => find_contacts.map(&:id)},
    #                            :order => "updated_on DESC")

    contacts = find_contacts(false)
    deals = find_deals

    joins = " "
    joins << " LEFT OUTER JOIN #{Contact.table_name} ON #{Note.table_name}.source_id = #{Contact.table_name}.id AND #{Note.table_name}.source_type = 'Contact' "
    joins << " LEFT OUTER JOIN #{Deal.table_name} ON #{Note.table_name}.source_id = #{Deal.table_name}.id AND #{Note.table_name}.source_type = 'Deal' "
    cond = "(1 = 1) "
    cond << "and (#{Contact.table_name}.id in (#{contacts.any? ? contacts.map(&:id).join(', ') : 'NULL'})"

    cond << " or #{Deal.table_name}.id in (#{deals.any? ? deals.map(&:id).join(', ') : 'NULL'}))"
    cond << " and (LOWER(#{Note.table_name}.content) LIKE '%#{params[:search_note].downcase}%')" if params[:search_note] and request.xhr?
    cond << " and (#{Note.table_name}.author_id = #{params[:note_author_id]})" if !params[:note_author_id].blank?
    cond << " and (#{Note.table_name}.type_id = #{params[:type_id]})" if !params[:type_id].blank?


    @notes_pages, @notes = paginate :notes,
                                    :per_page => 20,
                                    :joins => joins,
                                    :conditions => cond,
                                    :order => "#{Note.table_name}.created_on DESC"
    @notes.compact!


    respond_to do |format|
      format.html { render :partial => "notes/notes_list", :layout => false, :locals => {:notes => @notes, :notes_pages => @notes_pages} if request.xhr?}
      format.xml { render :xml => @notes }
      format.csv { send_data(notes_to_csv(@notes), :type => 'text/csv; header=present', :filename => 'notes.csv') }
      format.atom { render_feed(@notes, :title => "#{l(:label_crm_note_plural)}")  }
    end
  end


  def context_menu
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    @contacts = Contact.visible.where(:id => params[:selected_contacts])
    @contact = @contacts.first if (@contacts.size == 1)
    @can = {:edit => (@contact && @contact.editable?) || (@contacts && @contacts.collect{|c| c.editable?}.inject{|memo,d| memo && d}),
            :create_deal => (@project && User.current.allowed_to?(:add_deals, @project)),
            :create => (@project && User.current.allowed_to?(:add_contacts, @project)),
            :delete => @contacts.collect{|c| c.deletable?}.inject{|memo,d| memo && d},
            :send_mails => @contacts.collect{|c| c.send_mail_allowed? && !c.primary_email.blank?}.inject{|memo,d| memo && d}
            }

    # @back = back_url
    render :layout => false
  end

  def bulk_destroy
    @contacts = Contact.deletable.find_all_by_id(params[:ids])
    raise ActiveRecord::RecordNotFound if @contacts.empty?
    @contacts.each(&:destroy)
    redirect_back_or_default({:action => "index", :project_id => params[:project_id]})
  end
  def bulk_edit
    @contacts = Contact.editable.find_all_by_id(params[:ids])
    @projects = @contacts.collect{|p| p.projects.compact}.compact.flatten.uniq
    raise ActiveRecord::RecordNotFound if @contacts.empty?
    @tag_list = ActsAsTaggableOn::TagList.from(@contacts.map(&:tag_list).inject{|memo,t| memo | t})
    @project = @projects.first
    @assignables = @projects.map(&:assignable_users).inject{|memo,a| memo & a}
    @add_projects = Project.allowed_to(:edit_contacts).order(:lft)
  end

  def bulk_update
    @contacts = Contact.editable.find_all_by_id(params[:ids])
    raise ActiveRecord::RecordNotFound if @contacts.empty?
    unsaved_contact_ids = []
    @contacts.each do |contact|
      contact.reload
      params[:contact][:tag_list] = (contact.tag_list + ActsAsTaggableOn::TagList.from(params[:add_tag_list]) - ActsAsTaggableOn::TagList.from(params[:delete_tag_list])).uniq

      add_project_ids = (!params[:add_projects_list].to_s.blank? && params[:add_projects_list].is_a?(Array))  ? Project.allowed_to(:edit_contacts).where(:id => params[:add_projects_list].collect{|p| p.to_i}).map(&:id) : []
      delete_project_ids = (!params[:delete_projects_list].to_s.blank? && params[:delete_projects_list].is_a?(Array)) ? Project.allowed_to(:edit_contacts).where(:id => params[:delete_projects_list].collect{|p| p.to_i}).map(&:id) : []
      project_ids = contact.project_ids + add_project_ids - delete_project_ids
      params[:contact][:project_ids] = project_ids if project_ids.any?

      contact.tags.clear
      unless contact.update_attributes(parse_params_for_bulk_contact_attributes(params))
        # Keep unsaved issue ids to display them in flash error
        unsaved_contact_ids << contact.id
      end
      if !params[:note][:content].blank?
        note = ContactNote.new(params[:note])
        note.author = User.current
        contact.notes << note
      end

    end
    set_flash_from_bulk_contact_save(@contacts, unsaved_contact_ids)
    redirect_back_or_default({:controller => 'contacts', :action => 'index', :project_id => @project})
  end

  def edit_mails
    @contacts = Contact.visible.find_all_by_id(params[:ids]).reject{|c| c.email.blank?}
    raise ActiveRecord::RecordNotFound if @contacts.empty?
    if !@contacts.collect{|c| c.send_mail_allowed?}.inject{|memo,d| memo && d}
      deny_access
      return
    end
  end

  def send_mails
    contacts = Contact.visible.find_all_by_id(params[:ids])
    raise ActiveRecord::RecordNotFound if contacts.empty?
    if !contacts.collect{|c| c.send_mail_allowed?}.inject{|memo,d| memo && d}
      deny_access
      return
    end
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    delivered_contacts = []
    error_contacts = []
    contacts.each do |contact|
      begin
        params[:message] = mail_macro(contact, params[:"message-content"])
        ContactsMailer.bulk_mail(contact, params).deliver
        delivered_contacts << contact

        note = ContactNote.new
        note.subject = params[:subject]
        note.content = params[:message]
        note.author = User.current
        note.type_id = Note.note_types[:email]
        contact.notes << note
        Attachment.attach_files(note, params[:attachments])
        render_attachment_warning_if_needed(note)

      rescue Exception => e
        error_contacts << [contact, e.message]
      end
      flash[:notice] = l(:notice_email_sent, delivered_contacts.map{|c| "#{c.name} <span class='icon icon-email'>#{c.emails.first}</span>"}.join(', ')).chomp[0,500] if delivered_contacts.any?
      flash[:error] = l(:notice_email_error, error_contacts.map{|e| "#{e[0].name}: #{e[1]}"}.join(', ')).chomp[0,500] if error_contacts.any?
    end

    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_back_or_default({:controller => 'contacts', :action => 'index', :project_id => @project})
  end

  def preview_email
    @text = mail_macro(Contact.visible.first(:conditions => {:id  => params[:ids][0]}), params[:"message-content"])
    render :partial => 'common/preview'
  end

private
  def attach_avatar
    if params[:contact_avatar]
      params[:contact_avatar][:description] = 'avatar'
      @contact.avatar.destroy if @contact.avatar
      Attachment.attach_files(@contact, {"1" => params[:contact_avatar]})
      render_attachment_warning_if_needed(@contact)
    end
  end

  def last_notes(count=5)
    # @last_notes = find_contacts(false).find(:all, :include => :notes, :limit => count,  :order => 'notes.created_on DESC').map{|c| c.notes}.flatten.first(count)
    scope = ContactNote.scoped({})
    scope = scope.scoped(:conditions => ["#{Project.table_name}.id = ?", @project.id]) if @project
    scope = scope.includes(:attachments)

    @last_notes = scope.visible.find(:all,
                                     :limit => count,
                                     :order => "#{ContactNote.table_name}.created_on DESC")
    # @last_notes = []
  end

  def find_contact
    @contact = Contact.find(params[:id])
    unless @contact.visible?
      deny_access
      return
    end
    project_id = (params[:contact] && params[:contact][:project_id]) || params[:project_id]
    @project = Project.find_by_identifier(project_id)
    @project ||= @contact.project
    # if !(params[:project_id] == @project.identifier)
    #   params[:project_id] = @project.identifier
    #   redirect_to params
    # end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def find_deals
    scope = Deal.scoped({})
    scope = scope.scoped(:conditions => ["#{Deal.table_name}.project_id = ?", @project.id]) if @project
    scope = scope.scoped(:conditions => ["#{Deal.table_name}.name LIKE ? ", "%" + params[:search] + "%"]) if params[:search]
    scope = scope.scoped(:conditions => ["1=0"]) if params[:tag]
    @deals = scope.visible.find(:all) || []
  end

  def find_contacts(pages=true)
    @tag = ActsAsTaggableOn::TagList.from(params[:tag]) unless params[:tag].blank?

    scope = Contact.scoped({})
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.job_title = ?", params[:job_title]]) unless params[:job_title].blank?
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.assigned_to_id = ?", params[:assigned_to_id]]) unless params[:assigned_to_id].blank?
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.is_company = ?", params[:query]]) unless (params[:query].blank? || params[:query] == '2' || params[:query] == '3')
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.author_id = ?", User.current]) if params[:query] == '3'

    case params[:query]
      when '2' then scope = scope.order_by_creation
      when '3' then scope = scope.order_by_creation
      else scope = scope.order_by_name
    end

    scope = scope.by_project(@project)

    params[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } if !params[:search].blank?
    scope = scope.visible

    scope = scope.tagged_with(params[:tag]) if !params[:tag].blank?
    scope = scope.tagged_with(params[:notag], :exclude => true) if !params[:notag].blank?

    @contacts_count = scope.count
    @contacts = scope

    if pages
      page_size = params[:page_size].blank? ? 20 : params[:page_size].to_i
      @contacts_pages = Paginator.new(self, @contacts_count, page_size, params[:page])
      @offset = @contacts_pages.current.offset
      @limit =  @contacts_pages.items_per_page

      @contacts = @contacts.scoped :include => [:tags, :avatar], :limit  => @limit, :offset => @offset

      fake_name = @contacts.first.name if @contacts.length > 0
    end
    @contacts

  end

  # Filter for bulk issue operations
  def bulk_find_contacts
    @contacts = Deal.find_all_by_id(params[:id] || params[:ids], :include => :project)
    raise ActiveRecord::RecordNotFound if @contact.empty?
    if @contacts.detect {|contact| !contact.visible?}
      deny_access
      return
    end
    @projects = @contacts.collect(&:projects).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end


  def parse_params_for_bulk_contact_attributes(params)
    attributes = (params[:contact] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes
  end

  def find_project
    project_id = (params[:contact] && params[:contact][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_contacts(action = params[:action], global = false)
    case action.to_s
    when 'edit', 'update'
      @contact.editable? ? true : deny_access
    when 'destroy'
      @contact.deletable? ? true : deny_access
    else
      deny_access
    end
  end

end
