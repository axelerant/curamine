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

class ContactsQuery < ActiveRecord::Base
  unloadable

  class StatementInvalid < ::ActiveRecord::StatementInvalid
  end

  belongs_to :project
  belongs_to :user
  serialize :filters
  serialize :column_names
  serialize :sort_criteria, Array

  attr_protected :project_id, :user_id

  validates_presence_of :name
  validates_length_of :name, :maximum => 255
  validate :validate_query_filters

  @@operators = { "="   => :label_equals,
                  "!"   => :label_not_equals,
                  "o"   => :label_open_issues,
                  "c"   => :label_closed_issues,
                  "!*"  => :label_none,
                  "*"   => :label_all,
                  ">="  => :label_greater_or_equal,
                  "<="  => :label_less_or_equal,
                  "><"  => :label_between,
                  "<t+" => :label_in_less_than,
                  ">t+" => :label_in_more_than,
                  "t+"  => :label_in,
                  "t"   => :label_today,
                  "w"   => :label_this_week,
                  ">t-" => :label_less_than_ago,
                  "<t-" => :label_more_than_ago,
                  "t-"  => :label_ago,
                  "~"   => :label_contains,
                  "!~"  => :label_not_contains }

  cattr_reader :operators

  @@operators_by_filter_type = { :list => [ "=", "!" ],
                                 :list_status => [ "o", "=", "!", "c", "*" ],
                                 :list_optional => [ "=", "!", "!*", "*" ],
                                 :list_subprojects => [ "*", "!*", "=" ],
                                 :date => [ "=", ">=", "<=", "><", "<t+", ">t+", "t+", "t", "w", ">t-", "<t-", "t-", "!*", "*" ],
                                 :date_past => [ "=", ">=", "<=", "><", ">t-", "<t-", "t-", "t", "w", "!*", "*" ],
                                 :string => [ "=", "~", "!", "!~" ],
                                 :text => [  "~", "!~" ],
                                 :integer => [ "=", ">=", "<=", "><", "!*", "*" ],
                                 :float => [ "=", ">=", "<=", "><", "!*", "*" ] }

  cattr_reader :operators_by_filter_type

  @@available_columns = [
    QueryColumn.new(:name, :sortable => "#{Contact.table_name}.last_name, #{Contact.table_name}.first_name", :caption => :field_contact_full_name),
    QueryColumn.new(:first_name, :sortable => "#{Contact.table_name}.first_name"),
    QueryColumn.new(:last_name, :sortable => "#{Contact.table_name}.last_name"),
    QueryColumn.new(:middle_name, :sortable => "#{Contact.table_name}.middle_name", :caption => :field_contact_middle_name),
    QueryColumn.new(:job_title, :sortable => "#{Contact.table_name}.job_title", :caption => :field_contact_job_title, :groupable => true),
    QueryColumn.new(:company, :sortable => "#{Contact.table_name}.company", :caption => :field_contact_company, :groupable => true),
    QueryColumn.new(:phone, :sortable => "#{Contact.table_name}.phone", :caption => :field_contact_phone),
    QueryColumn.new(:email, :sortable => "#{Contact.table_name}.email", :caption => :field_contact_email),
    QueryColumn.new(:city, :sortable => "#{Address.table_name}.city", :caption => :label_crm_city),
    QueryColumn.new(:region, :sortable => "#{Address.table_name}.region", :caption => :label_crm_region),
    QueryColumn.new(:postcode, :sortable => "#{Address.table_name}.postcode", :caption => :label_crm_postcode),
    QueryColumn.new(:country, :sortable => "#{Address.table_name}.country", :caption => :label_crm_country),
    QueryColumn.new(:address, :sortable => "#{Address.table_name}.full_address", :caption => :label_crm_address),
    QueryColumn.new(:created_on, :sortable => "#{Contact.table_name}.created_on"),
    QueryColumn.new(:updated_on, :sortable => "#{Contact.table_name}.updated_on"),
    QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => true),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement("authors")})
  ]
  cattr_reader :available_columns

  scope :visible, lambda {|*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :view_contacts, *args)
    user_id = user.logged? ? user.id : 0
    {
      :conditions => ["(#{table_name}.project_id IS NULL OR (#{base})) AND (#{table_name}.is_public = ? OR #{table_name}.user_id = ?)", true, user_id],
      :include => :project
    }
  }

  def initialize(attributes = nil)
    super attributes
    self.filters = {}
    @is_for_all = project.nil?
  end

  def build_from_params(params)
    if params[:fields] || params[:f]
      self.filters = {}
      add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
    else
      available_filters.keys.each do |field|
        add_short_filter(field, params[field]) if params[field]
      end
    end
    self.group_by = params[:group_by] || (params[:query] && params[:query][:group_by])
    self.column_names = params[:c] || (params[:query] && params[:query][:column_names])
    self
  end

  # Builds a new query from the given params and attributes
  def self.build_from_params(params, attributes={})
    new(attributes).build_from_params(params)
  end


  def validate_query_filters
    filters.each_key do |field|
      if values_for(field)
        case type_for(field)
        when :integer
          add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^[+-]?\d+$/) }
        when :float
          add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^[+-]?\d+(\.\d*)?$/) }
        when :date, :date_past
          case operator_for(field)
          when "=", ">=", "<=", "><"
            add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && (!v.match(/^\d{4}-\d{2}-\d{2}$/) || (Date.parse(v) rescue nil).nil?) }
          when ">t-", "<t-", "t-", ">t+", "<t+", "t+", "><t+", "><t-"
            add_filter_error(field, :invalid) if values_for(field).detect {|v| v.present? && !v.match(/^\d+$/) }
          end
        end
      end

      add_filter_error(field, :blank) unless
          # filter requires one or more values
          (values_for(field) and !values_for(field).first.blank?) or
          # filter doesn't require any value
          ["o", "c", "!*", "*", "t", "w"].include? operator_for(field)
    end if filters
  end

  def add_filter_error(field, message)
    m = label_for(field) + " " + l(message, :scope => 'activerecord.errors.messages')
    errors.add(:base, m)
  end

  # Returns true if the query is visible to +user+ or the current user.
  def visible?(user=User.current)
    (project.nil? || user.allowed_to?(:view_contacts, project)) && (self.is_public? || self.user_id == user.id)
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (!is_public && self.user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public && !@is_for_all && user.allowed_to?(:manage_public_contacts_queries, project)
  end

  def available_filters
    return @available_filters if @available_filters

    @available_filters = { "first_name" => { :type => :string, :order => 0 },
                           "last_name" => { :type => :string, :order => 1 },
                           "middle_name" => { :type => :string, :order => 2 },
                           "job_title" => { :type => :string, :order => 3 },
                           "company" => { :type => :string, :order => 4 },
                           "phone" => { :type => :text, :order => 5 },
                           "email" => { :type => :text, :order => 6 },
                           "full_address" => { :type => :text, :order => 7, :name => l(:label_crm_address) },
                           "city" => { :type => :text, :order => 8, :name => l(:label_crm_city)},
                           "region" => { :type => :text, :order => 9, :name => l(:label_crm_region)},
                           "postcode" => { :type => :text, :order => 10, :name => l(:label_crm_postcode)},
                           "country_code" => { :type => :list_optional, :values => l(:label_crm_countries).map{|k, v| [v, k]}, :order => 11, :name => l(:label_crm_country)},
                           "is_company" => { :type => :list, :values => [[l(:general_text_yes), ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')], [l(:general_text_no), ActiveRecord::Base.connection.quoted_false.gsub(/'/, '')]], :order => 12 },
                           "last_note" => { :type => :date_past, :order => 13 },
                           "has_deals" => {:type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 14, :name => l(:label_crm_has_deals)},
                           "updated_on" => { :type => :date_past, :order => 20 },
                           "created_on" => { :type => :date, :order => 21 }}

    principals = []
    if project
      principals += project.principals.sort
    else
      all_projects = Project.visible
      if all_projects.any?
        # members of visible projects
        principals += Principal.active.where("#{User.table_name}.id IN (SELECT DISTINCT user_id FROM members WHERE project_id IN (?))", all_projects.collect(&:id)).sort

      end
    end
    users = principals.select {|p| p.is_a?(User)}

    assigned_to_values = []
    assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    assigned_to_values += (Setting.issue_group_assignment? ? principals : users).collect{|s| [s.name, s.id.to_s] }
    @available_filters["assigned_to_id"] = { :type => :list_optional, :order => 7, :values => assigned_to_values } unless assigned_to_values.empty?

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect{|s| [s.name, s.id.to_s] }
    @available_filters["author_id"] = { :type => :list, :order => 8, :values => author_values } unless author_values.empty?

    issues_assignee_values = []
    issues_assignee_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    issues_assignee_values += (Setting.issue_group_assignment? ? principals : users).collect{|s| [s.name, s.id.to_s] }
    @available_filters["has_open_issues"] = { :type => :list_optional, :order => 7, :values => issues_assignee_values, :name => l(:label_crm_has_open_issues) } unless issues_assignee_values.empty?


    # if User.current.logged?
    #   @available_filters["watcher_id"] = { :type => :list, :order => 9, :values => [["<< #{l(:label_me)} >>", "me"]] }
    # end
    add_custom_fields_filters(ContactCustomField.find(:all, :conditions => {:is_filter => true}))

    tag_options = project.blank? ? {} : {:project => project.id}
    @available_filters["tags"] = {:type  => :list, :order  => 12,
              :values => Contact.available_tags(tag_options).collect{ |t| [t.name, t.name] }}

    @available_filters.each do |field, options|
      options[:name] ||= l("field_#{field}".gsub(/_id$/, ''))
    end

    @available_filters
  end

  # Returns a representation of the available filters for JSON serialization
  def available_filters_as_json
    json = {}
    available_filters.each do |field, options|
      json[field] = options.slice(:type, :name, :values).stringify_keys
    end
    json
  end

  def all_projects
    @all_projects ||= Project.visible
  end

  def all_projects_values
    return @all_projects_values if @all_projects_values

    values = []
    Project.project_tree(all_projects) do |p, level|
      prefix = (level > 0 ? ('--' * level + ' ') : '')
      values << ["#{prefix}#{p.name}", p.id.to_s]
    end
    @all_projects_values = values
  end

  def add_filter(field, operator, values)
    # values must be an array
    return unless values.nil? || values.is_a?(Array)
    # check if field is defined as an available filter
    if available_filters.has_key? field
      filter_options = available_filters[field]
      # check if operator is allowed for that filter
      #if @@operators_by_filter_type[filter_options[:type]].include? operator
      #  allowed_values = values & ([""] + (filter_options[:values] || []).collect {|val| val[1]})
      #  filters[field] = {:operator => operator, :values => allowed_values } if (allowed_values.first and !allowed_values.first.empty?) or ["o", "c", "!*", "*", "t"].include? operator
      #end
      filters[field] = {:operator => operator, :values => (values || [''])}
    end
  end

  def add_short_filter(field, expression)
    return unless expression && available_filters.has_key?(field)
    field_type = available_filters[field][:type]
    @@operators_by_filter_type[field_type].sort.reverse.detect do |operator|
      next unless expression =~ /^#{Regexp.escape(operator)}(.*)$/
      add_filter field, operator, $1.present? ? $1.split('|') : ['']
    end || add_filter(field, '=', expression.split('|'))
  end

  # Add multiple filters using +add_filter+
  def add_filters(fields, operators, values)
    if fields.is_a?(Array) && operators.is_a?(Hash) && (values.nil? || values.is_a?(Hash))
      fields.each do |field|
        add_filter(field, operators[field], values && values[field])
      end
    end
  end

  def has_filter?(field)
    filters and filters[field]
  end

  def type_for(field)
    available_filters[field][:type] if available_filters.has_key?(field)
  end

  def operator_for(field)
    has_filter?(field) ? filters[field][:operator] : nil
  end

  def values_for(field)
    has_filter?(field) ? filters[field][:values] : nil
  end

  def value_for(field, index=0)
    (values_for(field) || [])[index]
  end

  def label_for(field)
    label = available_filters[field][:name] if available_filters.has_key?(field)
    label ||= field.gsub(/\_id$/, "")
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = ::ContactsQuery.available_columns
    @available_columns += ContactCustomField.find(:all).collect {|cf| QueryCustomFieldColumn.new(cf) }
  end

  # Returns a Hash of columns and the key for sorting
  def sortable_columns
    {'id' => "#{Contact.table_name}.id"}.merge(available_columns.inject({}) {|h, column|
                                               h[column.name.to_s] = column.sortable
                                               h
                                             })
  end

  def self.available_columns=(v)
    self.available_columns = (v)
  end

  def self.add_available_column(column)
    self.available_columns << (column) if column.is_a?(QueryColumn)
  end

  # Returns an array of columns that can be used to group the results
  def groupable_columns
    available_columns.select {|c| c.groupable}
  end

  def columns
    # preserve the column_names order
    (has_default_columns? ? default_columns_names : column_names).collect do |name|
       available_columns.find { |col| col.name == name }
    end.compact
  end

  def default_columns_names
    @default_columns_names ||= begin
      default_columns = %w(name job_title company phone email).map(&:to_sym)

      project.present? ? default_columns : [:project] | default_columns
    end
  end


  def column_names=(names)
    if names
      names = names.select {|n| n.is_a?(Symbol) || !n.blank? }
      names = names.collect {|n| n.is_a?(Symbol) ? n : n.to_sym }
      # Set column_names to nil if default columns
      if names == default_columns_names
        names = nil
      end
    end
    write_attribute(:column_names, names)
  end

  def has_column?(column)
    column_names && column_names.include?(column.is_a?(QueryColumn) ? column.name : column)
  end

  def has_default_columns?
    column_names.nil? || column_names.empty?
  end

  def sort_criteria=(arg)
    c = []
    if arg.is_a?(Hash)
      arg = arg.keys.sort.collect {|k| arg[k]}
    end
    c = arg.select {|k,o| !k.to_s.blank?}.slice(0,3).collect {|k,o| [k.to_s, o == 'desc' ? o : 'asc']}
    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    read_attribute(:sort_criteria) || []
  end

  def sort_criteria_key(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].last
  end

  # Returns the SQL sort order that should be prepended for grouping
  def group_by_sort_order
    if grouped? && (column = group_by_column)
      column.sortable.is_a?(Array) ?
        column.sortable.collect {|s| "#{s} #{column.default_order}"}.join(',') :
        "#{column.sortable} #{column.default_order}"
    end
  end

  # Returns true if the query is a grouped query
  def grouped?
    !group_by_column.nil?
  end

  def group_by_column
    groupable_columns.detect {|c| c.groupable && c.name.to_s == group_by}
  end

  def group_by_statement
    group_by_column.try(:groupable)
  end

  def project_statement
    project_clauses = []
    if project && !project.descendants.active.empty?
      ids = [project.id]
      if has_filter?("subproject_id")
        case operator_for("subproject_id")
        when '='
          # include the selected subprojects
          ids += values_for("subproject_id").each(&:to_i)
        when '!*'
          # main project only
        else
          # all subprojects
          ids += project.descendants.collect(&:id)
        end
      elsif Setting.display_subprojects_issues?
        ids += project.descendants.collect(&:id)
      end
      project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
    elsif project
      project_clauses << "#{Project.table_name}.id = %d" % project.id
    end
    project_clauses.any? ? project_clauses.join(' AND ') : nil
  end

  def statement
    # filters clauses
    filters_clauses = []
    filters.each_key do |field|
      next if field == "subproject_id"
      v = values_for(field).clone
      next unless v and !v.empty?
      operator = operator_for(field)

      # "me" value subsitution
      if %w(assigned_to_id author_id watcher_id has_open_issues).include?(field)
        if v.delete("me")
          if User.current.logged?
            v.push(User.current.id.to_s)
            v += User.current.group_ids.map(&:to_s) if field == 'assigned_to_id'
          else
            v.push("0")
          end
        end
      end

      if field =~ /^cf_(\d+)$/
        # custom field
        filters_clauses << sql_for_custom_field(field, operator, v, $1)
      elsif respond_to?("sql_for_#{field}_field")
        # specific statement
        filters_clauses << send("sql_for_#{field}_field", field, operator, v)
      elsif field == "last_note"
        filters_clauses << sql_for_last_note_field(field, operator, v)
      elsif field == "has_deals"
        filters_clauses << sql_for_has_deals_field(field, operator, v)
      elsif field == "has_open_issues"
        filters_clauses << sql_for_has_open_issues_field(field, operator, v)
      elsif %w(city region country_code postcode full_address).include?(field)
        filters_clauses << sql_for_address_field(field, operator, v)
      elsif field == "tags"
        compare   = operator_for('tags').eql?('=') ? 'IN' : 'NOT IN'
        ids_list  = Contact.tagged_with(v).collect{|contact| contact.id }.push(0).join(',')

        filters_clauses << "( #{Contact.table_name}.id #{compare} (#{ids_list}) ) "
      else
        # regular field
        filters_clauses << '(' + sql_for_field(field, operator, v, Contact.table_name, field) + ')'
      end


    end if filters and valid?

    filters_clauses << project_statement
    filters_clauses.reject!(&:blank?)

    filters_clauses.any? ? filters_clauses.join(' AND ') : nil
  end

  def sql_for_address_field(field, operator, value)
    sql_for_field(field, operator, value, Address.table_name, field)
  end

  # Returns the contact count
  def contact_count
    Contact.visible.includes(:address).count(:conditions => statement)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the contact count by group or nil if query is not grouped
  def contact_count_by_group
    r = nil
    if grouped?
      begin
        # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = Contact.visible.count(:group => group_by_statement, :conditions => statement)
      rescue ActiveRecord::RecordNotFound
        r = {nil => contact_count}
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the contacts
  # Valid options are :order, :offset, :limit, :include, :conditions
  def contacts(options={})
    order_option = [group_by_sort_order, options[:order]].reject {|s| s.blank?}.join(',')
    order_option = nil if order_option.blank?

    # joins = (order_option && order_option.include?('authors')) ? "LEFT OUTER JOIN users authors ON authors.id = #{Contact.table_name}.author_id" : nil

    joins = []
    if order_option
      if order_option.include?('authors')
        joins <<  "LEFT OUTER JOIN users authors ON authors.id = #{Contact.table_name}.author_id"
      end
      order_option.scan(/cf_\d+/).uniq.each do |name|
        column = available_columns.detect {|c| c.name.to_s == name}
        join = column && column.custom_field.join_for_order_statement
        if join
          joins << join
        end
      end
    end
    joins = joins.any? ? joins.join(' ') : nil


    scope = Contact.scoped({})

    options[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } unless options[:search].blank?
    options[:include] << :assigned_to if (order_option && order_option.include?('users'))
    scope.visible.scoped(:conditions => options[:conditions]).find :all, :include => ([:projects, :address] + (options[:include] || [])).uniq,
                     :conditions => statement,
                     :order => order_option,
                     :joins => joins,
                     :limit  => options[:limit],
                     :offset => options[:offset]
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  private

  def sql_for_has_deals_field(field, operator, value)
    db_table = Deal.table_name
    if operator == "!"
      "#{Contact.table_name}.id IN (
        SELECT #{db_table}.contact_id FROM #{db_table}
        GROUP BY #{db_table}.contact_id
        HAVING COUNT(#{db_table}.id) = 0)"
    else operator == "="
      "#{Contact.table_name}.id IN (
        SELECT #{db_table}.contact_id FROM #{db_table}
        GROUP BY #{db_table}.contact_id
        HAVING COUNT(#{db_table}.id) > 0)"
    end
  end

  def sql_for_has_open_issues_field(field, operator, value)
    db_table = ContactNote.table_name
    if operator == "!*"
      "#{Contact.table_name}.id IN (
        SELECT #{Contact.table_name}.id FROM #{Contact.table_name}
        LEFT JOIN contacts_issues ON contacts_issues.contact_id = #{Contact.table_name}.id
        LEFT JOIN #{Issue.table_name} ON contacts_issues.issue_id = #{Issue.table_name}.id
        LEFT JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id
        WHERE (#{IssueStatus.table_name}.is_closed = #{ActiveRecord::Base.connection.quoted_false}) OR (#{IssueStatus.table_name}.is_closed IS NULL)
        GROUP BY #{Contact.table_name}.id
        HAVING COUNT(#{Issue.table_name}.id) = 0)"
    elsif operator == "*"
      "#{Contact.table_name}.id IN (
        SELECT contacts_issues.contact_id FROM contacts_issues
        INNER JOIN #{Issue.table_name} ON contacts_issues.issue_id = #{Issue.table_name}.id
        INNER JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id
        WHERE #{IssueStatus.table_name}.is_closed = #{ActiveRecord::Base.connection.quoted_false}
        GROUP BY contacts_issues.contact_id
        HAVING COUNT(#{Issue.table_name}.id) > 0)"
    else
      "#{Contact.table_name}.id IN (
        SELECT contacts_issues.contact_id FROM contacts_issues
        INNER JOIN #{Issue.table_name} ON contacts_issues.issue_id = #{Issue.table_name}.id
        INNER JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id
        WHERE #{IssueStatus.table_name}.is_closed = #{ActiveRecord::Base.connection.quoted_false}
          AND #{sql_for_field("assigned_to_id", operator, value, Issue.table_name, 'assigned_to_id')}
        GROUP BY contacts_issues.contact_id)"
    end
  end

  def sql_for_last_note_field(field, operator, value)
    db_table = ContactNote.table_name
    if operator == "!*"
      "#{Contact.table_name}.id IN (
        SELECT #{Contact.table_name}.id FROM #{Contact.table_name}
        LEFT JOIN #{db_table} ON #{db_table}.source_id = #{Contact.table_name}.id and #{db_table}.source_type = 'Contact'
        GROUP BY #{Contact.table_name}.id
        HAVING COUNT(#{db_table}.id) = 0)"
    elsif operator == "*"
      "#{Contact.table_name}.id IN (
        SELECT #{Contact.table_name}.id FROM #{Contact.table_name}
        INNER JOIN #{db_table} ON #{db_table}.source_id = #{Contact.table_name}.id and #{db_table}.source_type = 'Contact'
        GROUP BY #{Contact.table_name}.id
        HAVING COUNT(#{db_table}.id) > 0)"
    else
      "#{Contact.table_name}.id IN (
        SELECT #{db_table}.source_id
        FROM #{db_table}
        WHERE #{db_table}.source_type='Contact'
        AND #{db_table}.id IN
          (SELECT MAX(#{db_table}.id)
           FROM #{db_table}
           WHERE #{db_table}.source_type='Contact'
           GROUP BY #{db_table}.source_id)
        AND #{sql_for_field(field, operator, value, db_table, 'created_on')}
      )"
    end
  end

  def sql_for_watcher_id_field(field, operator, value)
    db_table = Watcher.table_name
    "#{Contact.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='Contact' AND " +
      sql_for_field(field, '=', value, db_table, 'user_id') + ')'
  end

  def sql_for_member_of_group_field(field, operator, value)
    if operator == '*' # Any group
      groups = Group.all
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      groups = Group.all
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      groups = Group.find_all_by_id(value)
    end
    groups ||= []

    members_of_groups = groups.inject([]) {|user_ids, group|
      if group && group.user_ids.present?
        user_ids << group.user_ids
      end
      user_ids.flatten.uniq.compact
    }.sort.collect(&:to_s)

    '(' + sql_for_field("assigned_to_id", operator, members_of_groups, Contact.table_name, "assigned_to_id", false) + ')'
  end

  private
  def sql_for_custom_field(field, operator, value, custom_field_id)
    db_table = CustomValue.table_name
    db_field = 'value'
    filter = @available_filters[field]
    if filter && filter[:format] == 'user'
      if value.delete('me')
        value.push User.current.id.to_s
      end
    end
    not_in = nil
    if operator == '!'
      # Makes ! operator work for custom fields with multiple values
      operator = '='
      not_in = 'NOT'
    end
    "#{Contact.table_name}.id #{not_in} IN (SELECT #{Contact.table_name}.id FROM #{Contact.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Contact' AND #{db_table}.customized_id=#{Contact.table_name}.id AND #{db_table}.custom_field_id=#{custom_field_id} WHERE " +
      sql_for_field(field, operator, value, db_table, db_field, true) + ')'
  end
  # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter=false)
    sql = ''
    case operator
    when "="
      if value.any?
        case type_for(field)
        when :date, :date_past
          sql = date_clause(db_table, db_field, (Date.parse(value.first) rescue nil), (Date.parse(value.first) rescue nil))
        when :integer
          if is_custom_filter
            sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) = #{value.first.to_i})"
          else
            sql = "#{db_table}.#{db_field} = #{value.first.to_i}"
          end
        when :float
          if is_custom_filter
            sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) BETWEEN #{value.first.to_f - 1e-5} AND #{value.first.to_f + 1e-5})"
          else
            sql = "#{db_table}.#{db_field} BETWEEN #{value.first.to_f - 1e-5} AND #{value.first.to_f + 1e-5}"
          end
        else
          sql = "#{db_table}.#{db_field} IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
        end
      else
        # IN an empty set
        sql = "1=0"
      end
    when "!"
      if value.any?
        sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + "))"
      else
        # NOT IN an empty set
        sql = "1=1"
      end
    when "!*"
      sql = "#{db_table}.#{db_field} IS NULL"
      sql << " OR #{db_table}.#{db_field} = ''" if is_custom_filter
    when "*"
      sql = "#{db_table}.#{db_field} IS NOT NULL"
      sql << " AND #{db_table}.#{db_field} <> ''" if is_custom_filter
    when ">="
      if [:date, :date_past].include?(type_for(field))
        sql = date_clause(db_table, db_field, (Date.parse(value.first) rescue nil), nil)
      else
        if is_custom_filter
          sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) >= #{value.first.to_f})"
        else
          sql = "#{db_table}.#{db_field} >= #{value.first.to_f}"
        end
      end
    when "<="
      if [:date, :date_past].include?(type_for(field))
        sql = date_clause(db_table, db_field, nil, (Date.parse(value.first) rescue nil))
      else
        if is_custom_filter
          sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) <= #{value.first.to_f})"
        else
          sql = "#{db_table}.#{db_field} <= #{value.first.to_f}"
        end
      end
    when "><"
      if [:date, :date_past].include?(type_for(field))
        sql = date_clause(db_table, db_field, (Date.parse(value[0]) rescue nil), (Date.parse(value[1]) rescue nil))
      else
        if is_custom_filter
          sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) BETWEEN #{value[0].to_f} AND #{value[1].to_f})"
        else
          sql = "#{db_table}.#{db_field} BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
        end
      end
    when "o"
      sql = "#{Issue.table_name}.status_id IN (SELECT id FROM #{IssueStatus.table_name} WHERE is_closed=#{connection.quoted_false})" if field == "status_id"
    when "c"
      sql = "#{Issue.table_name}.status_id IN (SELECT id FROM #{IssueStatus.table_name} WHERE is_closed=#{connection.quoted_true})" if field == "status_id"
    when ">t-"
      sql = relative_date_clause(db_table, db_field, - value.first.to_i, 0)
    when "<t-"
      sql = relative_date_clause(db_table, db_field, nil, - value.first.to_i)
    when "t-"
      sql = relative_date_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
    when ">t+"
      sql = relative_date_clause(db_table, db_field, value.first.to_i, nil)
    when "<t+"
      sql = relative_date_clause(db_table, db_field, 0, value.first.to_i)
    when "t+"
      sql = relative_date_clause(db_table, db_field, value.first.to_i, value.first.to_i)
    when "t"
      sql = relative_date_clause(db_table, db_field, 0, 0)
    when "w"
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = Date.today.cwday
      days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      sql = relative_date_clause(db_table, db_field, - days_ago, - days_ago + 6)
    when "~"
      sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    when "!~"
      sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    else
      raise "Unknown query operator #{operator}"
    end

    return sql
  end

  def add_custom_fields_filters(custom_fields)
    @available_filters ||= {}

    custom_fields.select(&:is_filter?).each do |field|
      case field.field_format
      when "text"
        options = { :type => :text, :order => 20 }
      when "list"
        options = { :type => :list_optional, :values => field.possible_values, :order => 20}
      when "date"
        options = { :type => :date, :order => 20 }
      when "bool"
        options = { :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 20 }
      when "int"
        options = { :type => :integer, :order => 20 }
      when "float"
        options = { :type => :float, :order => 20 }
      when "user", "version"
        next unless project
        values = field.possible_values_options(project)
        if User.current.logged? && field.field_format == 'user'
          values.unshift ["<< #{l(:label_me)} >>", "me"]
        end
        options = { :type => :list_optional, :values => values, :order => 20}
      else
        options = { :type => :string, :order => 20 }
      end
      @available_filters["cf_#{field.id}"] = options.merge({ :name => field.name, :format => field.field_format })
    end
  end

  # Returns a SQL clause for a date or datetime field.
  def date_clause(table, field, from, to)
    s = []
    if from
      from_yesterday = from - 1
      from_yesterday_utc = Time.gm(from_yesterday.year, from_yesterday.month, from_yesterday.day)
      s << ("#{table}.#{field} > '%s'" % [connection.quoted_date(from_yesterday_utc.end_of_day)])
    end
    if to
      to_utc = Time.gm(to.year, to.month, to.day)
      s << ("#{table}.#{field} <= '%s'" % [connection.quoted_date(to_utc.end_of_day)])
    end
    s.join(' AND ')
  end

  # Returns a SQL clause for a date or datetime field using relative dates.
  def relative_date_clause(table, field, days_from, days_to)
    date_clause(table, field, (days_from ? Date.today + days_from : nil), (days_to ? Date.today + days_to : nil))
  end
end
