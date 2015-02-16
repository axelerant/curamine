# encoding: utf-8
#
# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2015 RedmineCRM
# http://www.redminecrm.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

module RedmineAgile
  module AgileHelper

    def retrieve_agile_query
      if !params[:query_id].blank?
        cond = "project_id IS NULL"
        cond << " OR project_id = #{@project.id}" if @project
        @query = AgileQuery.where(cond).find(params[:query_id])
        raise ::Unauthorized unless @query.visible?
        @query.project = @project
        session[:agile_query] = {:id => @query.id, :project_id => @query.project_id}
        sort_clear
      elsif api_request? || params[:set_filter] || session[:agile_query].nil? || session[:agile_query][:project_id] != (@project ? @project.id : nil)
        @query = AgileQuery.default_query(@project) || AgileQuery.default_query unless params[:set_filter]
        unless @query
          @query = AgileQuery.new(:name => "_")
          @query.build_from_params(params)
        end
        @query.project = @project
        session[:agile_query] = {:project_id => @query.project_id,
                                 :filters => @query.filters,
                                 :group_by => @query.group_by,
                                 :color_base => (@query.respond_to?(:color_base) && @query.color_base),
                                 :column_names => @query.column_names}
      else
        # retrieve from session
        @query = nil
        @query ||= AgileQuery.default_query(@project) || AgileQuery.default_query
        @query ||= AgileQuery.find_by_id(session[:agile_query][:id]) if session[:agile_query][:id]
        @query ||= AgileQuery.new(:name => "_",
                                  :filters => session[:agile_query][:filters],
                                  :group_by => session[:agile_query][:group_by],
                                  :color_base => session[:agile_query][:color_base],
                                  :column_names => session[:agile_query][:column_names])
        @query.project = @project
      end
    end
    def agile_query_links(title, queries)
      return '' if queries.empty?
      # links to #index on issues/show
      url_params = {:controller => 'agile_boards', :action => 'index', :project_id => @project}

      content_tag('h3', title) + "\n" +
        content_tag('ul',
          queries.collect {|query|
              css = 'query'
              css << ' selected' if query == @query
              content_tag('li', link_to(query.name, url_params.merge(:query_id => query), :class => css))
            }.join("\n").html_safe,
          :class => 'queries'
        ) + "\n"
    end


    def sidebar_agile_queries
      unless @sidebar_agile_queries
        @sidebar_agile_queries = AgileQuery.visible.
          order("#{Query.table_name}.name ASC").
          # Project specific queries and global queries
          where(@project.nil? ? ["project_id IS NULL"] : ["project_id IS NULL OR project_id = ?", @project.id]).
          all
      end
      @sidebar_agile_queries
    end

    def render_sidebar_agile_queries
      out = ''.html_safe
      out << agile_query_links(l(:label_agile_my_boards), sidebar_agile_queries.select {|q| !q.is_public?})
      out << agile_query_links(l(:label_agile_board_plural), sidebar_agile_queries.reject {|q| !q.is_public?})
      out
    end

    def options_card_colors_for_select(selected, options={})
      options_for_select([[l(:label_agile_color_no_colors), "none"],
        [l(:label_issue), "issue"],
        [l(:label_tracker), "tracker"],
        [l(:field_priority), "priority"]].compact,
        selected)
    end

    def options_charts_for_select(selected, options={})
      options_for_select([[l(:label_agile_charts_issues_burndown), "issues_burndown"],
        [l(:label_agile_charts_work_burndown), "work_burndown"],
        [l(:label_agile_charts_burnup), "burnup"],
        [l(:label_agile_charts_work_burnup), "work_burnup"],
        [l(:label_agile_charts_cumulative_flow), "cumulative_flow"],
        [l(:label_agile_charts_issues_velocity), "issues_velocity"],
        [l(:label_agile_charts_lead_time), "lead_time"],
        [l(:label_agile_charts_average_lead_time), "average_lead_time"],
        [l(:label_agile_charts_trackers_cumulative_flow), "trackers_cumulative_flow"],
        nil].compact,
        selected)
    end

    def render_agile_chart(chart_name, issues_scope)
      render :partial => "agile_charts/chart", :locals => {:chart => chart_name, :issues_scope => issues_scope}
    end

  end
end

ActionView::Base.send :include, RedmineAgile::AgileHelper
