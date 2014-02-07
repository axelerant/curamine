class CannedResponse < ActiveRecord::Base
  unloadable

  belongs_to :project
  belongs_to :user

  validates_presence_of :name, :content
  validates_length_of :name, :maximum => 255  

  scope :visible, lambda {|*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :view_helpdesk_tickets, *args)
    user_id = user.logged? ? user.id : 0

    includes(:project).where("(#{table_name}.project_id IS NULL OR (#{base})) AND (#{table_name}.is_public = ? OR #{table_name}.user_id = ?)", true, user_id)
  }

  scope :in_project_or_public, lambda {|project|
    where("(#{table_name}.project_id IS NULL AND #{table_name}.is_public = ?) OR #{table_name}.project_id = ?", true, project)
  }

  # Returns true if the query is visible to +user+ or the current user.
  def visible?(user=User.current)
    (project.nil? || user.allowed_to?(:view_helpdesk_tickets, project)) && (self.is_public? || self.user_id == user.id)
  end

end
