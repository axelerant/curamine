require_dependency "calendars_controller"

module AdvancedRoadmap
  module CalendarsControllerPatch
    def self.included(base)
      base.class_eval do

        around_filter :add_milestones, :only => [:show]

        def add_milestones
          yield
          view = ActionView::Base.new(File.join(File.dirname(__FILE__), "..", "..", "app", "views"))
          view.class_eval do
            include ApplicationHelper
          end
          milestones = []
          @query.milestones(:conditions => ["effective_date BETWEEN ? AND ?",
                                            @calendar.startdt,
                                            @calendar.enddt]).each do |milestone|
            milestones << {:name => milestone.name,
                           :url => url_for(:controller => :milestones,
                                           :action => :show,
                                           :id => milestone.id),
                           :day => milestone.effective_date.day}
          end
          response.body += view.render(:partial => "hooks/calendars/milestones",
                                       :locals => {:milestones => milestones})
        end

        # Overriden from Redmine v2.3.1.
        # Added "#{Issue.quoted_table_name}." to Issue query.
        def show_with_scrum
          if params[:year] and params[:year].to_i > 1900
            @year = params[:year].to_i
            if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
              @month = params[:month].to_i
            end
          end
          @year ||= Date.today.year
          @month ||= Date.today.month

          @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
          retrieve_query
          @query.group_by = nil
          if @query.valid?
            events = []
            events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                                    :conditions => ["((#{Issue.quoted_table_name}.start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                                    )
            events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])

            @calendar.events = events
          end

          render :action => 'show', :layout => false if request.xhr?
        end
        alias_method_chain :show, :scrum

      end
    end
  end
end
