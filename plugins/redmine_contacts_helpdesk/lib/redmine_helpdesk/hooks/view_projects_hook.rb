module RedmineHelpdesk
  module Hooks
    class ViewProjectsHook < Redmine::Hook::ViewListener
      render_on :view_projects_show_sidebar_bottom, :partial => 'projects/helpdesk_tickets'
    end
  end
end
