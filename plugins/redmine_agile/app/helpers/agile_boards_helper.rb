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

module AgileBoardsHelper
  def agile_color_class(issue, options={})
    if options[:color_base]
      color = case options[:color_base]
      when AgileColor::COLOR_GROUPS[:issue]
        issue.color
      when AgileColor::COLOR_GROUPS[:tracker]
        issue.tracker.color
      when AgileColor::COLOR_GROUPS[:priority]
        issue.priority.color
      end
    else
      color = if RedmineAgile.tracker_colors?
        issue.tracker.color
      elsif RedmineAgile.issue_colors?
        issue.color
      elsif RedmineAgile.priority_colors?
        issue.priority.color
      end
    end
    "#{RedmineAgile.color_prefix}-#{color}" if color && RedmineAgile.use_colors?

  end

  def header_th(name, rowspan = 1, colspan = 1, leaf = nil)
    th_attributes = {}
    if leaf
      th_attributes[:style] = 'border-bottom: 4px solid; border-bottom-color: ' + color_by_name(leaf.name) if RedmineAgile.status_colors?
      th_attributes[:"data-column-id"] = leaf.id
      issue_count = leaf.instance_variable_get("@issue_count")
      count_tag = " (#{content_tag(:span, issue_count.to_i, :class => 'count')})".html_safe
    end
    th_attributes[:rowspan] = rowspan if rowspan > 1
    th_attributes[:colspan] = colspan if colspan > 1
    content_tag :th, h(name) + count_tag, th_attributes
  end

  def render_board_headers(columns)
    tree = HeaderTree.new

    columns.map do |column|
      path = column.name.split(':').map(&:strip)
      tree.put path, column
    end

    # puts tree

    maxdepth = tree.depth

    ret = tree.render

    ret[1..-1].map do |row|
      row.map do |th_params|
        header_th *th_params
      end
    end.map{|x| "<tr>#{x.join('')}</tr>" }.join.html_safe

  end

  def color_by_name(name)
    "##{"%06x" % (name.unpack('H*').first.hex % 0xffffff)}"
  end
  def format_swimlane_object(object, html=true)
    case object.class.name
    when 'Array'
      object.map {|o| format_swimlane_object(o, html)}.join(', ').html_safe
    when 'Time'
      format_time(object)
    when 'Date'
      format_date(object)
    when 'Fixnum'
      object.to_s
    when 'Float'
      sprintf "%.2f", object
    when 'User'
      html ? link_to_user(object) : object.to_s
    when 'Project'
      html ? link_to_project(object) : object.to_s
    when 'Version'
      html ? link_to(object.name, version_path(object)) : object.to_s
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    when 'Issue'
      object.visible? && html ? link_to_issue(object) : "##{object.id}"
    else
      html ? h(object) : object.to_s
    end
  end

  def render_board_fields_selection(query)
    query.available_inline_columns.reject(&:frozen?).map do |column|
      label_tag('', check_box_tag('c[]', column.name, query.columns.include?(column)) + column.caption, :class => "floating" )
    end.join(" ").html_safe
  end

  def render_issue_card_hours(query, issue)
    hours = []
    hours << "%.2f" % issue.total_spent_hours.to_f if query.has_column_name?(:spent_hours) && issue.total_spent_hours > 0
    hours << "%.2f" % issue.estimated_hours.to_f if query.has_column_name?(:estimated_hours) && issue.estimated_hours
    content_tag(:span, "(#{hours.join('/')}h)", :class => 'hours') unless hours.blank?
  end

  def agile_progress_bar(pcts, options={})
    pcts = [pcts, pcts] unless pcts.is_a?(Array)
    pcts = pcts.collect(&:round)
    pcts[1] = pcts[1] - pcts[0]
    pcts << (100 - pcts[1] - pcts[0])
    width = options[:width] || '100px;'
    legend = options[:legend] || ''
    content_tag('table',
      content_tag('tr',
        (pcts[0] > 0 ? content_tag('td', '', :style => "width: #{pcts[0]}%;", :class => 'closed') : ''.html_safe) +
        (pcts[1] > 0 ? content_tag('td', '', :style => "width: #{pcts[1]}%;", :class => 'done') : ''.html_safe) +
        (pcts[2] > 0 ? content_tag('td', '', :style => "width: #{pcts[2]}%;", :class => 'todo') : ''.html_safe) +
        (legend ? content_tag('td', content_tag('p', legend, :class => 'percent'), :class => 'legend') : ''.html_safe)
      ), :class => "progress progress-#{pcts[0]}", :style => "width: #{width};").html_safe
  end
end
