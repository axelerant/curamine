class ExtendedFieldsHook  < Redmine::Hook::ViewListener

    def view_layouts_base_html_head(context = {})
        stylesheet_link_tag('extended_fields', :plugin => 'extended_fields')
    end

    render_on :view_custom_fields_form_upper_box,         :partial => 'custom_fields/extended'
    render_on :view_custom_fields_form_user_custom_field, :partial => 'custom_fields/options'

end
