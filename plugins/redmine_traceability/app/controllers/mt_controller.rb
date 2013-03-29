class MtController < ApplicationController
  unloadable

  before_filter :find_project_by_project_id, :authorize, :get_trackers
  menu_item :traceability

  def index
    @issue_rows = @tracker_rows.issues.find(:all,
                                            :conditions => { :project_id => @project.id },
                                            :order => :id)
    @issue_cols = @tracker_cols.issues.find(:all,
                                            :conditions => { :project_id => @project.id },
                                            :order => :id)
    relations = IssueRelation.find(:all,
                                   :joins => 'INNER JOIN issues issue_from ON issue_from.id = issue_relations.issue_from_id ' +
                                             'INNER JOIN issues issue_to ON issue_to.id = issue_relations.issue_to_id ',
                                   :include => [ :issue_from, :issue_to ],
                                   :conditions => [ 'issue_from.project_id = :pid ' +
                                                    'AND issue_to.project_id = :pid ' +
                                                    'AND ((issue_from.tracker_id = :trows AND issue_to.tracker_id = :tcols) ' +
                                                         'OR (issue_from.tracker_id = :tcols AND issue_to.tracker_id = :trows))',
                                                    { :pid => @project.id, :trows => @tracker_rows.id, :tcols => @tracker_cols.id } ])

    @not_seen_issue_cols = @issue_cols.dup
    @issue_pairs = {}
    relations.each do |relation|
      if relation.issue_from.tracker_id == @tracker_rows.id
        @issue_pairs[relation.issue_from] ||= {}
        @issue_pairs[relation.issue_from][relation.issue_to] ||= []
        @issue_pairs[relation.issue_from][relation.issue_to] << true
        @not_seen_issue_cols.delete relation.issue_to
      else
        @issue_pairs[relation.issue_to] ||= {}
        @issue_pairs[relation.issue_to][relation.issue_from] ||= []
        @issue_pairs[relation.issue_to][relation.issue_from] << true
        @not_seen_issue_cols.delete relation.issue_from
      end
    end

    return unless @tracker_int

    int_to_rows = {}
    # Lookup intermediate tracker issue relations
    IssueRelation.find_each(:joins => 'INNER JOIN issues issue_from ON issue_from.id = issue_relations.issue_from_id ' +
                                      'INNER JOIN issues issue_to ON issue_to.id = issue_relations.issue_to_id ',
                            :conditions => [ 'issue_from.project_id = :pid ' +
                                             'AND issue_to.project_id = :pid ' +
                                             'AND ((issue_from.tracker_id = :trows AND issue_to.tracker_id = :tint) ' +
                                                  'OR (issue_from.tracker_id = :tint AND issue_to.tracker_id = :trows))',
                                             { :pid => @project.id,
                                               :trows => @tracker_rows.id,
                                               :tint => @tracker_int.id } ] ) do |relation|
      if relation.issue_from.tracker_id == @tracker_int.id
        int_to_rows[relation.issue_from] ||= []
        int_to_rows[relation.issue_from] << relation.issue_to
      else
        int_to_rows[relation.issue_to] ||= []
        int_to_rows[relation.issue_to] << relation.issue_from
      end
    end
    IssueRelation.find_each(:joins => 'INNER JOIN issues issue_from ON issue_from.id = issue_relations.issue_from_id ' +
                                      'INNER JOIN issues issue_to ON issue_to.id = issue_relations.issue_to_id ',
                            :conditions => [ 'issue_from.project_id = :pid ' +
                                             'AND issue_to.project_id = :pid ' +
                                             'AND ((issue_from.tracker_id = :tcols AND issue_to.tracker_id = :tint) ' +
                                                  'OR (issue_from.tracker_id = :tint AND issue_to.tracker_id = :tcols))',
                                             { :pid => @project.id,
                                               :tcols => @tracker_cols.id,
                                               :tint => @tracker_int.id } ] ) do |relation|
      if relation.issue_from.tracker_id == @tracker_int.id
        # relation.issue_from -> @tracker_int
        # relation.issue_to   -> @tracker_cols
        if int_to_rows.has_key? relation.issue_from
          int_to_rows[relation.issue_from].each do |row_issue|
            # row_issue -> @tracker_rows
            @issue_pairs[row_issue] ||= {}
            @issue_pairs[row_issue][relation.issue_to] ||= []
            @issue_pairs[row_issue][relation.issue_to] << relation.issue_from
            @not_seen_issue_cols.delete relation.issue_to
          end
        end
      else
        # relation.issue_from -> @tracker_cols
        # relation.issue_to   -> @tracker_int
        if int_to_rows.has_key? relation.issue_to
          int_to_rows[relation.issue_to].each do |row_issue|
            # row_issue -> @tracker_rows
            @issue_pairs[row_issue] ||= {}
            @issue_pairs[row_issue][relation.issue_from] ||= []
            @issue_pairs[row_issue][relation.issue_from] << relation.issue_to
            @not_seen_issue_cols.delete relation.issue_from
          end
        end
      end
    end
  end

  private

  def get_trackers
    @tracker_rows = Tracker.find(Setting.plugin_redmine_traceability['tracker0'])
    @tracker_cols = Tracker.find(Setting.plugin_redmine_traceability['tracker1'])
    if Setting.plugin_redmine_traceability['tracker2'].present?
      @tracker_int = Tracker.first(:conditions => {:id => Setting.plugin_redmine_traceability['tracker2']})
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = l(:'traceability.setup')
    render
  end
end
