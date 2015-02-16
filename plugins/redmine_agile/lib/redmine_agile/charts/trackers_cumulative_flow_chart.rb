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
  class TrackersCumulativeFlowChart < AgileChart

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

      Tracker.where(:id => @data_scope.group("#{Issue.table_name}.tracker_id").count.keys).sorted.each do |tracker|
        created_by_date = @data_scope.
          where(:tracker_id => tracker.id).
          where("#{Issue.table_name}.created_on >= ?", @date_from).
          where("#{Issue.table_name}.created_on <= ?", @date_to).
          where("#{Issue.table_name}.created_on IS NOT NULL").
          group("#{Issue.table_name}.created_on").
          count
        created_by_period = issues_count_by_period(created_by_date)

        total_issues = @data_scope.
                          where(:tracker_id => tracker.id).
                          where("#{Issue.table_name}.created_on < ?", @date_from).count
        cumulative_created_by_period = created_by_period.map{|x| total_issues += x}

        graph.add_data({
            :data => cumulative_created_by_period,
            :title => tracker.name
        }) unless created_by_period.empty?

      end


      graph.burn
    end

  end
end
