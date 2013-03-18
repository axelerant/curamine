function toggle_extended_field_format() {
    format = $('#custom_field_field_format')[0];
    required = $('#custom_field_is_required')[0];
    p_default = $('#custom_field_default_value')[0];

    switch (format.value) {
        case 'text':
        case 'wiki':
            if (p_default.tagName.toLowerCase() != 'textarea') {
                $(p_default).replaceWith(jQuery('<textarea />', { id:   'custom_field_default_value',
                                                                  name: 'custom_field[default_value]',
                                                                  cols: 40,
                                                                  rows: 15 }).text(p_default.value));
            }
            break;
        default:
            break;
    }
}
