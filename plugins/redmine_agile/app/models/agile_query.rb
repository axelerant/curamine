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

class AgileQuery < Query
  unloadable

  attr_reader :truncated

  self.queried_class = Issue

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{Issue.table_name}.id", :default_order => 'desc', :caption => :label_agile_issue_id),
    QueryColumn.new(:project, :groupable => "#{Issue.table_name}.project_id"),
    QueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position", :groupable => true),
    QueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours"),
    QueryColumn.new(:done_ratio, :sortable => "#{Issue.table_name}.done_ratio"),
    QueryColumn.new(:priority, :sortable => "#{IssuePriority.table_name}.position", :default_order => 'desc', :groupable => true),
    QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement("users")}, :groupable => true),
    QueryColumn.new(:category, :sortable => "#{IssueCategory.table_name}.name", :groupable => "#{Issue.table_name}.category_id"),
    QueryColumn.new(:fixed_version, :sortable => lambda {Version.fields_for_order_statement}, :groupable => "#{Issue.table_name}.fixed_version_id"),
    QueryColumn.new(:start_date, :sortable => "#{Issue.table_name}.start_date"),
    QueryColumn.new(:due_date, :sortable => "#{Issue.table_name}.due_date"),
    QueryColumn.new(:thumbnails, :caption => :label_agile_board_thumbnails),
    QueryColumn.new(:description),
    QueryColumn.new(:parent, :groupable => "#{Issue.table_name}.parent_id", :sortable => "#{AgileRank.table_name}.position", :caption => :field_parent_issue),
    QueryColumn.new(:assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => "#{Issue.table_name}.assigned_to_id")
  ]
  before_save :set_default_when_appropriate

  scope :visible, lambda {|*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :view_issues, *args)
    scope = eager_load(:project).where("#{table_name}.project_id IS NULL OR (#{base})")

    if user.admin?
      scope.where("#{table_name}.visibility <> ? OR #{table_name}.user_id = ?", VISIBILITY_PRIVATE, user.id)
    elsif user.memberships.any?
      scope.where("#{table_name}.visibility = ?" +
        " OR (#{table_name}.visibility = ? AND #{table_name}.id IN (" +
          "SELECT DISTINCT q.id FROM #{table_name} q" +
          " INNER JOIN #{table_name_prefix}queries_roles#{table_name_suffix} qr on qr.query_id = q.id" +
          " INNER JOIN #{MemberRole.table_name} mr ON mr.role_id = qr.role_id" +
          " INNER JOIN #{Member.table_name} m ON m.id = mr.member_id AND m.user_id = ?" +
          " WHERE q.project_id IS NULL OR q.project_id = m.project_id))" +
        " OR #{table_name}.user_id = ?",
        VISIBILITY_PUBLIC, VISIBILITY_ROLES, user.id, user.id)
    elsif user.logged?
      scope.where("#{table_name}.visibility = ? OR #{table_name}.user_id = ?", VISIBILITY_PUBLIC, user.id)
    else
      scope.where("#{table_name}.visibility = ?", VISIBILITY_PUBLIC)
    end
  }

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
    @truncated = false
  end

  def card_columns
    self.inline_columns.select{|c| !%w(tracker thumbnails description assigned_to done_ratio spent_hours estimated_hours project id).include?(c.name.to_s)}
  end

  def visible?(user=User.current)
    return true if user.admin?
    return false unless project.nil? || user.allowed_to?(:view_issues, project)
    case visibility
    when VISIBILITY_PUBLIC
      true
    when VISIBILITY_ROLES
      if project
        (user.roles_for_project(project) & roles).any?
      else
        Member.where(:user_id => user.id).joins(:roles).where(:member_roles => {:role_id => roles.map(&:id)}).any?
      end
    else
      user == self.user
    end
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def is_public?
    !is_private?
  end

  def color_base
    options[:color_base] || RedmineAgile.color_base
  end

  def color_base=(value)
    options[:color_base] = value
  end
  def is_default?
    !!options[:is_default]
  end

  def is_default=(value)
    options[:is_default] = !!value
  end

  def set_as_default
    AgileQuery.where(:project_id => self.project_id).where(:visibility => self.visibility).where("#{AgileQuery.table_name}.id <> ?", self.id).each do |query|
      query.is_default = false
      query.save
    end if self.is_default?
  end

  def self.default_query(project=nil)
    board_scope = AgileQuery.visible
    board_scope = board_scope.where(:project_id => project)
    default_query = board_scope.where("#{table_name}.visibility = ? AND #{table_name}.user_id = ?", VISIBILITY_PRIVATE, User.current).detect{|q| q.is_default?}
    default_query ||= board_scope.includes(:user => :memberships).where("#{table_name}.visibility = ?", VISIBILITY_ROLES).detect{|q| q.is_default?}
    default_query ||= board_scope.where("#{table_name}.visibility = ?", VISIBILITY_PUBLIC).detect{|q| q.is_default?}
    default_query
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
    self.color_base = params[:color_base] || (params[:query] && params[:query][:color_base])
    self.is_default = params[:is_default] || (params[:query] && params[:query][:is_default])
    self
  end

  # Builds a new query from the given params and attributes
  def self.build_from_params(params, attributes={})
    new(attributes).build_from_params(params)
  end

  def initialize_available_filters
    principals = []
    subprojects = []
    versions = []
    categories = []
    issue_custom_fields = []

    if project
      principals += project.principals.sort
      unless project.leaf?
        subprojects = project.descendants.visible.all
        principals += Principal.member_of(subprojects)
      end
      versions = project.shared_versions.all
      categories = project.issue_categories.all
      issue_custom_fields = project.all_issue_custom_fields
    else
      if all_projects.any?
        principals += Principal.member_of(all_projects)
      end
      versions = Version.visible.where(:sharing => 'system').all
      issue_custom_fields = IssueCustomField.where(:is_for_all => true)
    end
    principals.uniq!
    principals.sort!
    users = principals.select {|p| p.is_a?(User)}

    add_available_filter "status_id",
      :type => :list_status, :values => IssueStatus.sorted.collect{|s| [s.name, s.id.to_s] }

    if project.nil?
      project_values = []
      if User.current.logged? && User.current.memberships.any?
        project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
      end
      project_values += all_projects_values
      add_available_filter("project_id",
        :type => :list, :values => project_values
      ) unless project_values.empty?
    end

    add_available_filter "tracker_id",
      :type => :list, :values => trackers.collect{|s| [s.name, s.id.to_s] }
    add_available_filter "priority_id",
      :type => :list, :values => IssuePriority.all.collect{|s| [s.name, s.id.to_s] }

    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect{|s| [s.name, s.id.to_s] }
    add_available_filter("author_id",
      :type => :list, :values => author_values
    ) unless author_values.empty?

    assigned_to_values = []
    assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    assigned_to_values += (Setting.issue_group_assignment? ?
                              principals : users).collect{|s| [s.name, s.id.to_s] }
    add_available_filter("assigned_to_id",
      :type => :list_optional, :values => assigned_to_values
    ) unless assigned_to_values.empty?

    group_values = Group.all.collect {|g| [g.name, g.id.to_s] }
    add_available_filter("member_of_group",
      :type => :list_optional, :values => group_values
    ) unless group_values.empty?

    role_values = Role.givable.collect {|r| [r.name, r.id.to_s] }
    add_available_filter("assigned_to_role",
      :type => :list_optional, :values => role_values
    ) unless role_values.empty?

    if versions.any?
      add_available_filter "fixed_version_id",
        :type => :list_optional,
        :values => versions.sort.collect{|s| ["#{s.project.name} - #{s.name}", s.id.to_s] }
    end

    if categories.any?
      add_available_filter "category_id",
        :type => :list_optional,
        :values => categories.collect{|s| [s.name, s.id.to_s] }
    end

    add_available_filter "subject", :type => :text
    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past
    add_available_filter "closed_on", :type => :date_past
    add_available_filter "start_date", :type => :date
    add_available_filter "due_date", :type => :date
    add_available_filter "estimated_hours", :type => :float
    add_available_filter "done_ratio", :type => :integer
    add_available_filter "parent_issue_id", :type => :relation
    add_available_filter "version_status", :type => :list,
      :name => l("label_attribute_of_fixed_version", :name => 'status'),
      :values => Version::VERSION_STATUSES.collect {|s| [l("version_status_#{s}"), s]}

    if subprojects.any?
      add_available_filter "subproject_id",
        :type => :list_subprojects,
        :values => subprojects.collect{|s| [s.name, s.id.to_s] }
    end


    add_custom_fields_filters(issue_custom_fields)

    add_associations_custom_fields_filters :project, :author, :assigned_to, :fixed_version

    Tracker.disabled_core_fields(trackers).each {|field|
      delete_available_filter field
    }
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += (project ?
                            project.all_issue_custom_fields :
                            IssueCustomField
                           ).visible.collect {|cf| QueryCustomFieldColumn.new(cf) }

    if User.current.allowed_to?(:view_time_entries, project, :global => true)
      index = nil
      @available_columns.each_with_index {|column, i| index = i if column.name == :estimated_hours}
      index = (index ? index + 1 : -1)
      # insert the column after estimated_hours or at the end
      @available_columns.insert index, QueryColumn.new(:spent_hours,
        :sortable => "COALESCE((SELECT SUM(hours) FROM #{TimeEntry.table_name} WHERE #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id), 0)",
        :default_order => 'desc',
        :caption => :label_spent_time
      )
    end

    disabled_fields = Tracker.disabled_core_fields(trackers).map {|field| field.sub(/_id$/, '')}
    @available_columns.reject! {|column|
      disabled_fields.include?(column.name.to_s)
    }

    @available_columns.reject! {|column| column.name == :done_ratio} unless Issue.use_field_for_done_ratio?

    @available_columns
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (is_private? && self.user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public? && !@is_for_all && user.allowed_to?(:manage_public_agile_queries, project)
  end

  def default_columns_names
    @default_columns_names = RedmineAgile.default_columns.map(&:to_sym)
  end

  def has_column_name?(name)
    columns.detect{|c| c.name == name}
  end

  def groupable_columns
    available_columns.select {|c| c.groupable && !c.is_a?(QueryCustomFieldColumn)}
  end

  def sql_for_version_status_field(field, operator, value)
     sql_for_field(field, operator, value, Version.table_name, "status")
  end

  def sql_for_parent_issue_id_field(field, operator, value, options={})
    sql = case operator
      when "*", "!*", "=", "!"
        sql_for_field(field, operator, value, queried_table_name, "parent_id")
      when "=p", "=!p", "!p"
        op = (operator == "!p" ? 'NOT IN' : 'IN')
        comp = (operator == "=!p" ? '<>' : '=')
        "#{Issue.table_name}.parent_id #{op} (SELECT DISTINCT #{Issue.table_name}.id FROM #{Issue.table_name} WHERE #{Issue.table_name}.project_id #{comp} #{value.first.to_i})"
      end
    "(#{sql})"
  end

  def sql_for_member_of_group_field(field, operator, value)
    if operator == '*' # Any group
      groups = Group.all
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == "!*"
      groups = Group.all
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      groups = Group.where(:id => value).all
    end
    groups ||= []

    members_of_groups = groups.inject([]) {|user_ids, group|
      user_ids + group.user_ids + [group.id]
    }.uniq.compact.sort.collect(&:to_s)

    '(' + sql_for_field("assigned_to_id", operator, members_of_groups, Issue.table_name, "assigned_to_id", false) + ')'
  end

  def sql_for_assigned_to_role_field(field, operator, value)
    case operator
    when "*", "!*" # Member / Not member
      sw = operator == "!*" ? 'NOT' : ''
      nl = operator == "!*" ? "#{Issue.table_name}.assigned_to_id IS NULL OR" : ''
      "(#{nl} #{Issue.table_name}.assigned_to_id #{sw} IN (SELECT DISTINCT #{Member.table_name}.user_id FROM #{Member.table_name}" +
        " WHERE #{Member.table_name}.project_id = #{Issue.table_name}.project_id))"
    when "=", "!"
      role_cond = value.any? ?
        "#{MemberRole.table_name}.role_id IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")" :
        "1=0"

      sw = operator == "!" ? 'NOT' : ''
      nl = operator == "!" ? "#{Issue.table_name}.assigned_to_id IS NULL OR" : ''
      "(#{nl} #{Issue.table_name}.assigned_to_id #{sw} IN (SELECT DISTINCT #{Member.table_name}.user_id FROM #{Member.table_name}, #{MemberRole.table_name}" +
        " WHERE #{Member.table_name}.project_id = #{Issue.table_name}.project_id AND #{Member.table_name}.id = #{MemberRole.table_name}.member_id AND #{role_cond}))"
    end
  end

  def issues(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    scope = issue_scope.
      joins(:status, :project).
      includes((options[:include] || []).uniq).
      where(options[:conditions]).
      order(order_option).
      joins(joins_for_order_statement(order_option.join(','))).
      limit(options[:limit]).
      offset(options[:offset])

    scope = scope.preload(:custom_values)
    if has_column?(:author)
      scope = scope.preload(:author)
    end
    if color_base == AgileColor::COLOR_GROUPS[:issue]
      scope = scope.includes(:agile_color)
    end

    if color_base == AgileColor::COLOR_GROUPS[:priority]
      scope = scope.includes(:priority => :agile_color)
    end

    if color_base == AgileColor::COLOR_GROUPS[:tracker]
      scope = scope.includes(:tracker => :agile_color)
    end

    scope
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def board_statuses
    status_filter_operator = filters.fetch("status_id", {}).fetch(:operator, nil)
    status_filter_values = filters.fetch("status_id", {}).fetch(:values, [])
    statuses = IssueStatus.where(:id => Tracker.eager_load(:issues => [:status, :project, :fixed_version]).where(statement).map(&:issue_statuses).flatten.uniq.map(&:id))
    result_statuses = case status_filter_operator
    when "o"
      statuses.where(:is_closed => false).sorted
    when "c"
      statuses.where(:is_closed => true).sorted
    when "="
      statuses.where(:id => status_filter_values).sorted
    when "!"
      statuses.where("#{IssueStatus.table_name}.id NOT IN (" + status_filter_values.map{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")").sorted
    else
      statuses.sorted
    end
    result_statuses.map do |s|
      s.instance_variable_set "@issue_count", self.issue_count_by_status[s.id].to_i
      s
    end
  end
  def swimlanes
    return [] unless self.grouped?
    lane_ids = issue_scope.group(self.group_by_column.groupable).count.keys
    lanes = Issue.reflect_on_association(self.group_by_column.name).klass.where(:id => lane_ids).reorder(group_by_sort_order)
    lanes = lanes.includes(:agile_rank) if self.group_by_column.name == :parent
    lanes << nil if lane_ids.include?(nil)
    lanes
  end

  def issue_count_by_swimlane
    @issue_count_by_swimlane ||= issue_scope.group("#{Issue.table_name}.#{self.group_by_column.name}_id").count if self.grouped?
  end

  def issue_count_by_status
    @issue_count_by_status ||= issue_scope.group("#{Issue.table_name}.status_id").count
  end

  def issue_board(options={})
    @truncated = RedmineAgile.board_items_limit <= issue_scope.count
    all_issues = self.issues.limit(RedmineAgile.board_items_limit).sorted_by_rank
    self.grouped? ? all_issues.group_by{|i| [i.status_id, i.send("#{self.group_by_column.name}_id")]} : all_issues.group_by{|i| [i.status_id]}

  end

private
  def issue_scope
    Issue.visible.
      includes(:status,
               :project,
               :assigned_to,
               :tracker,
               :priority,
               :category,
               :fixed_version).
      where(statement)
  end
  def set_default_when_appropriate
    if options[:is_default]
      set_as_default
    end
  end

end
