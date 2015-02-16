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

require 'SVG/Graph/Bar'

module RedmineAgile
  class VelocityChart < AgileChart

    def initialize(data_scope, options={})
      @date_from = (options[:date_from] || data_scope.minimum("#{Issue.table_name}.created_on")).to_date
      @date_to = options[:date_to] || Date.today
      @style_sheet = "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_agile/stylesheets/charts/lead_time.css"
      super data_scope, options
    end

    def render
      created_by_period = issues_avg_count_by_period(scope_by_created_date)
      closed_by_period = issues_avg_count_by_period(scope_by_closed_date)


      if @scale_division > 1
        y_title = l(:label_agile_charts_avarate_number_of_issues)
        graph_title = l(:label_agile_charts_average_velocity)
      else
        y_title = l(:label_agile_charts_number_of_issues)
        graph_title = l(:label_agile_charts_issues_velocity)
      end

      graph = SVG::Graph::Bar.new(
        :height => 400,
        :width => 800,
        :fields => @fields,
        :stack => :side,
        :scale_integers => true,
        :min_scale_value => 0,
        :show_popups => true,
        :step_x_labels => @step_x_labels,
        :stagger_x_labels => true,
        :show_y_title => true,
        :y_title => y_title,
        :show_data_values => false,
        :no_css => true,
        :style_sheet => @style_sheet,
        :graph_title => graph_title,
        :show_graph_title => true
      )

      graph.add_data(
        :data => closed_by_period,
        :title => l(:field_closed_on)
      ) unless closed_by_period.empty?

      graph.add_data(
        :data => created_by_period,
        :title => l(:field_created_on)
      ) unless created_by_period.empty?

      graph.burn
    end

  end
end
