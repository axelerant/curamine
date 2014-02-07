module RedmineHelpdesk
  module Hooks
    class ViewContactsHook < Redmine::Hook::ViewListener
      render_on :view_contacts_context_menu_before_delete, :partial => "context_menus/helpdesk_contacts" 
    end
  end
end
