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

class DealsController < ApplicationController
  unloadable

  PRICE_TYPE_PULLDOWN = [l(:label_price_fixed_bid), l(:label_price_per_hour)]

  before_filter :find_deal, :only => [:show, :edit, :update, :destroy]
  before_filter :find_project, :only => [:new, :create, :update_form]
  before_filter :bulk_find_deals, :only => [:bulk_update, :bulk_edit, :bulk_destroy, :context_menu]
  before_filter :authorize, :except => [:index]
  before_filter :find_optional_project, :only => [:index]
  before_filter :update_deal_from_params, :only => [:edit, :update]
  before_filter :build_new_deal_from_params, :only => [:new, :update_form]
  before_filter :find_deal_attachments, :only => :show

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :attachments
  helper :contacts
  helper :notes
  helper :timelog
  helper :watchers
  helper :custom_fields
  helper :context_menus
  helper :sort
  helper :contacts_queries
  include ContactsQueriesHelper
  include CustomFieldsHelper
  include WatchersHelper
  include DealsHelper
  include ContactsHelper
  include SortHelper

  def new
  end

  def create
    @deal = Deal.new
    @deal.safe_attributes = params[:deal]
    @deal.project = @project
    @deal.author ||= User.current
    @deal.init_deal_process(User.current)
    if @deal.save
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.html { redirect_to (params[:continue] ?  {:action => "new"} : {:action => "show", :id => @deal} )}
        format.api  { render :action => 'show', :status => :created, :location => deal_url(@deal) }
      end

    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@deal) }
      end
    end
  end

  def update
    @deal.init_deal_process(User.current)
    @deal.safe_attributes = params[:deal]
    if @deal.save
      # @deal.contacts = [Contact.find(params[:contacts])] if params[:contacts]
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_back_or_default({:action => 'show', :id => @deal}) }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@deal) }
      end
    end

  end

  def edit
    respond_to do |format|
      format.html { }
      format.xml  { }
    end
  end

  def index
    retrieve_deals_query
    params[:status_id] = "o" unless params.has_key?(:status_id)
    find_deals
    respond_to do |format|
      format.html { request.xhr? ? render(:partial => deals_list_style, :layout => false, :locals => {:deals => @deals}) : last_notes }
      format.csv { send_data(deals_to_csv(find_deals(false)), :type => 'text/csv; header=present', :filename => 'deals.csv') }
      format.api
    end
  end

  def show
    @note = DealNote.new
    respond_to do |format|
      format.html do
       @deal.viewed
       @deal_events = (@deal.deal_processes.where("#{DealProcess.table_name}.old_value IS NOT NULL").includes([:to, :from, :author]) | @deal.notes.includes([:attachments, :author])).map{|o| {:date => o.is_a?(DealProcess) ? o.created_at : o.created_on, :author => o.author, :object => o} }
       @deal_events.sort!{|x, y| y[:date] <=> x[:date] }
      end
      format.api
    end
  end

  def destroy
    if @deal.destroy
      flash[:notice] = l(:notice_successful_delete)
      respond_to do |format|
        format.html { redirect_to :action => "index", :project_id => params[:project_id] }
        format.api { render_api_ok }
      end
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end

  end

  def context_menu
    @deal = @deals.first if (@deals.size == 1)
    @can = {:edit => User.current.allowed_to?(:edit_deals, @projects),
            :delete => User.current.allowed_to?(:delete_deals, @projects)
            }

    @back = back_url
    render :layout => false
  end

  def bulk_destroy
    @deals.each do |deal|
      begin
        deal.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if deal no longer exists
        # nothing to do, deal was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(:action => 'index', :project_id => params[:project_id]) }
      format.api  { head :ok }
    end
  end

  def bulk_edit
    @available_statuses = @projects.map(&:deal_statuses).inject{|memo,w| memo & w}
    @available_categories = @projects.map(&:deal_categories).inject{|memo,w| memo & w}
    @assignables = @projects.map(&:assignable_users).inject{|memo,a| memo & a}
  end

  def bulk_update
    unsaved_deal_ids = []
    @deals.each do |deal|
      deal.reload
      deal.init_deal_process(User.current)
      unless deal.update_attributes(parse_params_for_bulk_deal_attributes(params))
        # Keep unsaved deal ids to display them in flash error
        unsaved_deal_ids << deal.id
      end
      if params[:note] && !params[:note][:content].blank?
        note = DealNote.new(params[:note])
        note.author = User.current
        deal.notes << note
      end

    end
    set_flash_from_bulk_contact_save(@deals, unsaved_deal_ids)
    redirect_back_or_default({:controller => 'deals', :action => 'index', :project_id => @project})
  end

  private

  def last_notes(count=5)
    # TODO: Исправить говнокод этот и выделить все в плагин acts-as-noteble
      scope = DealNote.scoped({})
      scope = scope.scoped(:conditions => ["#{Deal.table_name}.project_id = ?", @project.id]) if @project

      @last_notes = scope.visible.find(:all,
                                          :limit => count,
                                          :order => "#{DealNote.table_name}.created_on DESC")
  end


  def build_new_deal_from_params
    if params[:id].blank?
      @deal = Deal.new
      @deal.assigned_to_id = User.current.id
      @deal.name = params[:name] if params[:name]
      @deal.contact = Contact.find(params[:contact_id]) if params[:contact_id]
      if params[:copy_from]
        begin
          @copy_from = Deal.visible.find(params[:copy_from])
          @deal.copy_from(@copy_from)
        rescue ActiveRecord::RecordNotFound
          render_404
          return
        end
      end
    else
      @deal = Deal.visible.find(params[:id])
    end

    @deal.project = @project
    @deal.author ||= User.current
    @deal.safe_attributes = params[:deal]

    @available_watchers = (@deal.project.users.sort + @deal.watcher_users).uniq
  end

  def update_deal_from_params
  end

  def update_form
  end

  def find_deal_attachments
    @deal_attachments = Attachment.find(:all,
                                    :conditions => { :container_type => "Note", :container_id => @deal.notes.map(&:id)},
                                    :order => "created_on DESC")
  end


  def find_deals(pages=true)
    retrieve_date_range(params[:period].to_s)

    scope = Deal.scoped({})
    scope = scope.scoped(:conditions => ["#{Deal.table_name}.project_id = ?", @project.id]) if @project
    scope = scope.scoped(:conditions => ["#{Deal.table_name}.status_id = ?", params[:status_id]]) if (!params[:status_id].blank? && params[:status_id] != "o") && !(@project && !@project.deal_statuses.any?) && DealStatus.any? && (deals_list_style != 'list_board')
    scope = scope.scoped(:conditions => ["#{Deal.table_name}.category_id = ?", params[:category_id]]) if !params[:category_id].blank?
    scope = scope.scoped(:conditions => ["#{Deal.table_name}.assigned_to_id = ?", params[:assigned_to_id]]) if !params[:assigned_to_id].blank?
    scope = scope.scoped(:conditions => ["#{Deal.table_name}.probability = ?", params[:probability]]) if !params[:probability].blank?
    scope = scope.scoped(:conditions => ["#{Deal.table_name}.created_on BETWEEN ? AND ?", @from, @to]) if (@from && @to)

    params[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } if !params[:search].blank?
    scope = scope.visible
    scope = scope.open if (params[:status_id] == "o" && !(@project && !@project.deal_statuses.any?)) && DealStatus.any?
    @deals_sum = scope.group(:currency).sum(:price)
    @deals_scope = scope

    sort_init 'status', 'created_on'
    sort_update 'status' => 'status_id',
                'id' => "#{Deal.table_name}.id",
                'category' => 'category_id',
                'probability' => 'probability',
                'price' => 'price',
                'updated_on' => "#{Deal.table_name}.updated_on",
                'due_date' => 'due_date',
                'name' => "#{Deal.table_name}.name"

    scope = scope.scoped(:order => sort_clause) if sort_clause

    @deals_count = scope.count

    if pages
      @limit =  per_page_option

      # per_page = params[:per_page].blank? ? 20 : params[:per_page].to_i
      @deals_pages = Paginator.new(self, @deals_count, @limit, params[:page])
      @offset = @deals_pages.current.offset

      scope = scope.scoped :limit  => @limit, :offset => @offset
      @deals = scope

      fake_name = @deals.first.price if @deals.length > 0 #without this patch paging does not work
    end
    scope

  end

  def bulk_find_deals
    @deals = Deal.find_all_by_id(params[:id] || params[:ids], :include => :project)
    raise ActiveRecord::RecordNotFound if @deals.empty?
    if @deals.detect {|deal| !deal.visible?}
      deny_access
      return
    end
    @projects = @deals.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_deal
    @deal = Deal.find(params[:id], :include => [:project, :status, :category])
    @project = @deal.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    project_id = (params[:deal] && params[:deal][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def parse_params_for_bulk_deal_attributes(params)
    attributes = (params[:deal] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes
  end

end
