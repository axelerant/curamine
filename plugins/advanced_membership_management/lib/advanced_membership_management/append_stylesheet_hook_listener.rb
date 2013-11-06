class AppendStylesheetHookListener < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context)
      stylesheet_link_tag 'automatic_memberships', :plugin => :advanced_membership_management
  end
end