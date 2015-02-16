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
  class LeadTimeChart < AgileChart

    def initialize(data_scope, options={})
      @date_from = (options[:date_from] || data_scope.minimum("#{Issue.table_name}.created_on")).to_date
      @date_to = options[:date_to] || Date.today
      @average_lead_time = !!options[:average_lead_time]
      if @average_lead_time
        @style_sheet = "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_agile/stylesheets/charts/avg_lead_time.css"
      else
        @style_sheet = "#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_agile/stylesheets/charts/lead_time.css"
      end
      super data_scope, options
    end

    def render
      @average_lead_time ? render_average_lead_time : render_lead_time
    end

    private

    def render_lead_time
      lead_time_by_date = closed_issues.map{|c| {:closed_on => c.closed_on.localtime,  :lead_time => (c.closed_on.to_time.localtime - c.created_on.localtime.to_time).to_f / (60 * 60 * 24) }}
      lead_time_arr_by_period = {}
      lead_time_by_date.each do |c|
        next if c[:closed_on].to_date > @date_to.to_date
        period_num = ((@date_to.to_date - c[:closed_on].localtime.to_date).to_i / @scale_division).to_i
        lead_time_arr_by_period[period_num] = [] if lead_time_arr_by_period[period_num].blank?
        lead_time_arr_by_period[period_num] << c[:lead_time]
      end

      lead_time_by_period = [0] * @period_count
      for period_num in 0..@period_count - 1  do
        next if lead_time_arr_by_period[period_num].blank?
        arr = lead_time_arr_by_period[period_num]
        len = arr.length
        sorted = arr.sort
        median = len % 2 == 1 ? sorted[len/2] : (sorted[len/2 - 1] + sorted[len/2]).to_f / 2
        lead_time_by_period[period_num] = median
      end
      lead_time_by_period.reverse!


      graph = SVG::Graph::Bar.new({
        :height => 400,
        :width => 800,
        :fields => @fields,
        :step_x_labels => @step_x_labels,
        :stagger_x_labels => true,
        :show_y_title => true,
        :y_title => l(:label_agile_charts_number_of_days),
        :stack => :side,
        :scale_integers => true,
        :show_popups => true,
        :stagger_x_labels => true,
        :show_data_values => false,
        :no_css => true,
        :style_sheet => @style_sheet,
        :graph_title => l(:label_agile_charts_lead_time),
        :show_graph_title => true
      })

      graph.add_data({
          :data => lead_time_by_period,
          :title => l(:field_closed_on)
      }) unless lead_time_by_period.empty?

      graph.burn
    end

    def render_average_lead_time
      lead_time_by_date = closed_issues.map{|c| {:closed_on => c.closed_on,  :lead_time => (c.closed_on.to_time - c.created_on.to_time).to_f / (60 * 60 * 24) }}
      lead_time_by_period = [0] * @period_count
      lead_time_by_date.each do |c|
        next if c[:closed_on].to_date > @date_to.to_date
        period_num = (@date_to.to_date - c[:closed_on].to_date).to_i / @scale_division
        if lead_time_by_period[period_num]
          lead_time_by_period[period_num] = c[:lead_time] unless lead_time_by_period[period_num].to_i > 0
          lead_time_by_period[period_num] = (lead_time_by_period[period_num].to_f + c[:lead_time]).to_f / 2
        end
      end
      lead_time_by_period.reverse!

      prev_lead_time = lead_time_by_period[0]
      lead_time_by_period.each_with_index do |c, index|
        lead_time_by_period[index] = c == 0 ? prev_lead_time : (c + prev_lead_time).to_f / 2
        prev_lead_time = lead_time_by_period[index]
      end


      graph = SVG::Graph::Line.new({
        :height => 400,
        :width => 800,
        :fields => @fields,
        :step_x_labels => @step_x_labels,
        :stagger_x_labels => true,
        :show_x_guidelines => true,
        :show_y_title => true,
        :y_title => l(:label_agile_charts_number_of_days),
        :scale_integers => true,
        :show_data_values => false,
        :show_data_points => true,
        :min_scale_value => 0,
        :area_fill => true,
        :no_css => true,
        :style_sheet => @style_sheet,
        :graph_title => l(:label_agile_charts_average_lead_time),
        :show_graph_title => true
      })

      graph.add_data({
          :data => lead_time_by_period,
          :title => l(:field_closed_on)
      }) unless lead_time_by_period.empty?

      graph.burn

    end

    def closed_issues
      @closed_issues ||= @data_scope.
        open(false).
        where("#{Issue.table_name}.closed_on IS NOT NULL").
        where("#{Issue.table_name}.closed_on >= ?", @date_from).
        where("#{Issue.table_name}.closed_on < ?", @date_to + 1).
        where("#{Issue.table_name}.created_on IS NOT NULL")
    end

  end
end
