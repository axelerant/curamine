class ExtendedProfileHook  < Redmine::Hook::ViewListener

    def view_layouts_base_html_head(context = {})
        stylesheet_link_tag('extended_profile', :plugin => 'extended_profile')
    end

    render_on :view_sidebar_author_box_bottom, :partial => 'extended_profile/author'
    render_on :view_account_left_bottom,       :partial => 'extended_profile/user'

end
