function toggle_extended_field_format() {
    format = $('custom_field_field_format');
    required = $('custom_field_is_required');
    p_length = $('custom_field_min_length');
    p_regexp = $('custom_field_regexp');
    p_default = $('custom_field_default_value');

    default_value = null;
    switch (p_default.tagName.toLowerCase()) {
        case 'input':
            switch (p_default.type.toLowerCase()) {
                case 'checkbox':
                    default_value = p_default.checked;
                    break;
                default:
                    default_value = p_default.value;
                    break;
            }
            break;
        default:
            default_value = p_default.value;
            break;
    }

    switch (format.value) {
        case 'text':
        case 'wiki':
            if (p_default.tagName.toLowerCase() != 'textarea') {
                Element.replace(p_default, new Element('textarea', { id:   'custom_field_default_value',
                                                                     name: 'custom_field[default_value]',
                                                                     cols: 40,
                                                                     rows: 15 }).update(default_value));
            }
            break;
        case 'bool':
            if ((p_default.tagName.toLowerCase() != 'input') && (p_default.type.toLowerCase() != 'checkbox')) {
                Element.replace(p_default, new Element('input', { type:    'checkbox',
                                                                  id:      'custom_field_default_value',
                                                                  name:    'custom_field[default_value]',
                                                                  value:   1,
                                                                  checked: default_value }));
            }
            break;
        case 'project':
            var select = new Element('select', { id:   'custom_field_default_value',
                                                 name: 'custom_field[default_value]' });
            if (required.checked) {
                if (default_value == "") {
                    select.insert(new Element('option').update(actionview_instancetag_blank_option));
                }
            } else {
                select.insert(new Element('option'));
            }
            for (var i = 0; i < projects.length; i++) {
                var option = new Element('option', { value: projects[i][1] }).update(projects[i][0])
                if (projects[i][1] == default_value) {
                    option.selected = true;
                }
                select.insert(option);
            }
            Element.replace(p_default, select);
            break;
        case 'user':
        case 'version':
            break;
        default:
            if ((p_default.tagName.toLowerCase() != 'input') && (p_default.type.toLowerCase() != 'text')) {
                Element.replace(p_default, new Element('input', { type:  'text',
                                                                  id:    'custom_field_default_value',
                                                                  name:  'custom_field[default_value]',
                                                                  value: default_value,
                                                                  size:  30 }));
            }
            break;
    }

    switch (format.value) {
        case 'wiki':
            Element.hide(p_regexp.parentNode);
            break;
        case 'project':
            Element.hide(p_length.parentNode);
            Element.hide(p_regexp.parentNode);
            break;
        default:
            break;
    }
}
