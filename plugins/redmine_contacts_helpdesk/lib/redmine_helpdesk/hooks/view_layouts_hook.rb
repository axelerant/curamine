module RedmineHelpdesk
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        return stylesheet_link_tag(:helpdesk, :plugin => 'redmine_contacts_helpdesk')
      end
    end
  end
end