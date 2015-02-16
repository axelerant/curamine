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
  class BurnupChart < AgileChart

    def initialize(data_scope, options={})
      @date_from = (options[:date_from] || data_scope.minimum("#{Issue.table_name}.created_on")).to_date
      @date_to = (options[:date_to] || Date.today).to_date

      @due_date = options[:due_date].to_date if options[:due_date]

      @style_sheet = "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_agile/stylesheets/charts/burnup.css"
      super data_scope, options

      @fields = [''] + @fields
    end

    def render
      return false unless calc_data.any?

      graph = SVG::Graph::AgileTimeSeries.new({
        :height => 400,
        :width => 800,
        :fields => @fields,
        :step_x_labels => @step_x_labels,
        :stagger_x_labels => true,
        :scale_x_divisions => 1,
        :show_x_guidelines => true,
        :scale_x_integers => true,
        :scale_y_integers => true,
        :show_data_values => false,
        :show_data_points => true,
        :show_y_title => true,
        :step_include_first_x_label => false,
        :y_title => l(:label_agile_charts_number_of_issues),
        :add_popups => true,
        :min_y_value => 0,
        :min_scale_value => 0,
        :area_fill => true,
        :no_css => true,
        :style_sheet => @style_sheet,
        :graph_title => l(:label_agile_charts_burnup),
        :show_graph_title => true
      })

      graph.add_data({
          :data => data_points(@cumulative_data),
          :title => l(:field_created_on)
      })


      graph.add_data({
          :data => data_points(@data),
          :title => l(:field_closed_on)
      })

      graph.add_data({
          :data => data_points(ideal_effort(@data.first, @cumulative_data.last)),
          :title => l(:label_agile_ideal_work_remaining)
      })

      graph.burn
    end

    protected

    def ideal_effort(start_data, end_data)
      data = [0] * (due_date_period - 1)
      active_periods = RedmineAgile.exclude_weekends? ? due_date_period - @weekend_periods.select{|p| p < due_date_period}.count : due_date_period
      avg_remaining_velocity = (end_data - start_data).to_f / active_periods.to_f
      sum = start_data.to_f
      data[0] = sum
      for i in 1..due_date_period - 1
        sum += avg_remaining_velocity unless RedmineAgile.exclude_weekends? && @weekend_periods.include?(i - 1)
        data[i] = (sum * 100).round / 100.0
      end
      data[due_date_period] = end_data
      data
    end

    def calc_data
      created_by_period = issues_count_by_period(scope_by_created_date)
      closed_by_period = issues_count_by_period(scope_by_closed_date)

      total_issues = @data_scope.where("#{Issue.table_name}.created_on < ?", @date_from).count
      total_closed = @data_scope.open(false).where("#{Issue.table_name}.closed_on < ?", @date_from).count

      sum = total_issues
      @cumulative_data = [total_issues] + created_by_period.first(current_date_period).map{|x| sum += x}
      sum = total_closed
      @data = [total_closed] + closed_by_period.first(current_date_period).map{|x| sum += x}
    end

  end
end
