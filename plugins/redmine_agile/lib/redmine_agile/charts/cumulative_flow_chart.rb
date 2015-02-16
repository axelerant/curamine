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
  class CumulativeFlowChart < AgileChart

    def initialize(data_scope, options={})
      @date_from = (options[:date_from] || data_scope.minimum("#{Issue.table_name}.created_on")).to_date
      @date_to = options[:date_to] || Date.today
      @style_sheet = "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_agile/stylesheets/charts/cumulative_flow.css"
      super data_scope, options
    end

    def render

      graph = SVG::Graph::Line.new({
        :height => 400,
        :width => 800,
        :fields => @fields,
        :step_x_labels => @step_x_labels,
        :stagger_x_labels => true,
        :show_x_guidelines => true,
        :show_y_title => true,
        :y_title => l(:label_agile_charts_number_of_issues),
        :scale_integers => true,
        :show_data_values => false,
        :show_data_points => false,
        :min_scale_value => 0,
        :area_fill => true,
        :stacked => true,
        :no_css => true,
        :style_sheet => @style_sheet,
        :graph_title => l(:label_agile_charts_cumulative_flow),
        :show_graph_title => true
      })

      all_issues = @data_scope.
        includes({:journals => {:details => :journal}})
      data = chart_dates_by_period.map do |date|
        issues = all_issues.select {|issue| issue.created_on.localtime.to_date <= date }
        test = issues.inject({}) do |accum, issue|
          status_details = issue.journals.map(&:details).flatten.select {|detail| 'status_id' == detail.prop_key }.sort_by{|a| a.journal.created_on }
          details_today_or_earlier = status_details.select {|a| a.journal.created_on.to_date <= date }

          last_status_change = details_today_or_earlier.last

          status = if last_status_change
            last_status_change.value.to_i
          elsif status_details.size > 0
            status_details.first.old_value.to_i
          else
            issue.status_id
          end

          accum[status] = accum[status].to_i + 1
          accum
        end
      end

      IssueStatus.where(:id => data.map(&:keys).flatten.uniq).sorted.each do |status|
        graph.add_data({
            :data => data.map{|d| d[status.id].to_i},
            :title => status.name
        }) unless data.empty?
      end
      graph.burn
    end

    private

    def available_statuses
      @available_statuses ||= IssueStatus.find(@data_scope.group("#{Issue.table_name}.status_id").count.keys).map
    end

  end
end
