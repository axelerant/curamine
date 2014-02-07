# encoding: utf-8
#
# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

include ContactsMoneyHelper

module ContactsHelper

  def contact_tabs(contact)
    contact_tabs = []
    contact_tabs << {:name => 'notes', :partial => 'contacts/notes', :label => l(:label_crm_note_plural)} if User.current.allowed_to?(:view_contacts, @project)
    contact_tabs << {:name => 'contacts', :partial => 'company_contacts', :label => l(:label_contact_plural) + (contact.company_contacts.visible.count > 0 ? " (#{contact.company_contacts.count})" : "")} if contact.is_company?
    contact_tabs << {:name => 'deals', :partial => 'deals/related_deals', :label => l(:label_deal_plural) + (contact.all_visible_deals.size > 0 ? " (#{contact.all_visible_deals.size})" : "") } if User.current.allowed_to?(:view_deals, @project)
    contact_tabs
  end

  def collection_for_visibility_select
    [[l(:label_crm_contacts_visibility_project), Contact::VISIBILITY_PROJECT],
     [l(:label_crm_contacts_visibility_public), Contact::VISIBILITY_PUBLIC],
     [l(:label_crm_contacts_visibility_private), Contact::VISIBILITY_PRIVATE]]
  end

  def contact_tag_url(tag_name, options={})
    {:controller => 'contacts',
     :action => 'index',
     :set_filter => 1,
     :project_id => @project,
     :fields => [:tags],
     :values => {:tags => [tag_name]},
     :operators => {:tags => '='}}.merge(options)
  end

  def tag_link(tag_name, options={})
    style = RedmineContacts.settings[:monochrome_tags].to_i > 0 ? {} : {:style => "background-color: #{tag_color(tag_name)}"}
    tag_count = options.delete(:count)
    tag_title = tag_count ? "#{tag_name} (#{tag_count})" : tag_name
    link = link_to tag_title, contact_tag_url(tag_name), options
    content_tag(:span, link, {:class => "tag-label-color"}.merge(style))
  end

  def tag_color(tag_name)
    "##{"%06x" % (tag_name.unpack('H*').first.hex % 0xffffff)}"
    # "##{"%06x" % (Digest::MD5.hexdigest(tag_name).hex % 0xffffff)}"
    # "##{"%06x" % (tag_name.hash % 0xffffff).to_s}"
  end

  def tag_links(tag_list, options={})
    content_tag(
              :span,
              tag_list.map{|tag| tag_link(tag, options)}.join(' ').html_safe,
              :class => "tag_list") if tag_list
  end

  def authorized_for_permission?(permission, project, global = false)
    User.current.allowed_to?(permission, project, :global => global)
  end

  def skype_to(skype_name, name = nil)
    return link_to skype_name, 'skype:' + skype_name + '?call' unless skype_name.blank?
  end

  def contacts_for_select(project, options = {})
    scope = Contact.scoped({})
    scope = scope.scoped.limit(options[:limit] || 500)
    scope = scope.scoped.companies if options.delete(:is_company)
    scope = scope.joins(:projects).uniq.where(Contact.visible_condition(User.current))
    scope = project ? scope.by_project(project) : scope.where("#{Project.table_name}.id <> -1")
    scope.sort!{|x, y| x.name <=> y.name }.collect {|m| [m.name, m.id.to_s]}
  end

  def link_to_remote_list_update(text, url_params)
    link_to_remote(text,
      {:url => url_params, :method => :get, :update => 'contact_list', :complete => 'window.scrollTo(0,0)'},
      {:href => url_for(:params => url_params)}
    )
  end

  def contacts_check_box_tags(name, contacts)
    s = ''
    contacts.each do |contact|
      s << "<label>#{ check_box_tag name, contact.id, false, :id => nil } #{contact_tag(contact, :no_link => true)}#{' (' + contact.company + ')' unless contact.company.blank? || contact.is_company? }</label>\n"
    end
    s.html_safe
  end

  def note_source_url(note_source, options = {})
    polymorphic_path(note_source, options.merge(:project_id => @project))
    # return {:controller => note_source.class.name.pluralize.downcase, :action => 'show', :project_id => @project, :id => note_source.id }
  end

  def link_to_source(note_source, options={})
    return link_to note_source.name, note_source_url(note_source, options)
  end

  def select_contact_tag(name, contact, options={})
    cross_project_contacts = !!options.delete(:cross_project_contacts)
    field_id = sanitize_to_id(name)
    is_select = !!options[:is_select]
    display_field = !!options[:display_field]
    include_blank = !!options[:include_blank]
    is_company = !!options[:is_company]
    add_contact = !!options[:add_contact]

    s = ""
    if is_select
      s << select_tag(name, options_for_select(contacts_for_select(cross_project_contacts ? nil : @project, :is_company => is_company), contact.try(:id)), :include_blank => include_blank)
    else
      s << autocomplete_contact_tag(name, contact, options.merge(:project_id => cross_project_contacts ? nil : @project))
    end

    if add_contact
      s << link_to(image_tag('add.png', :style => 'vertical-align: middle;'),
                new_project_contact_path(@project, :contact_field_name => name, :contacts_is_company => is_company),
                :remote => true,
                :method => 'get',
                :title => l(:label_crm_contact_new),
                :id => "#{field_id}_add_link",
                :style => (display_field || is_select) ? "" : "display: none;",
                :tabindex => 200) if authorize_for('contacts', 'new')
    end

    s.html_safe
  end

  def autocomplete_contact_tag(name, contact, options={})
    field_id = sanitize_to_id(name)
    display_field = !!options.delete(:display_field)
    span_id = field_id + '_selected_contact'
    link_id = field_id + '_edit_link'
    s = ""
    unless @heads_for_contacts_autocomplete_included
      s << javascript_include_tag(:contacts_autocomplete, :plugin => 'redmine_contacts')
      @heads_for_contacts_autocomplete_included = true
    end
    s << content_tag(:span, contact.to_s, :id => span_id)
    s << link_to(image_tag("edit.png", :alt => l(:label_edit), :style => "vertical-align:middle;"), "#",
            :onclick => "$('##{span_id}').hide(); $(this).hide(); $('##{field_id}_add_link').show(); $('##{field_id}').show(); $('##{field_id}').val(''); $('##{field_id}').focus(); return false;",
            :id => link_id,
            :style => display_field ? "display: none;" : "")
    s << text_field_tag(name, contact.blank? ? '' : contact.id, :style => display_field ? "" : "display: none;", :placeholder => l(:label_crm_contact_search), :id =>  field_id, :class => "autocomplete")
    s << javascript_tag("initContactsAutocomplete('#{name}', '#{escape_javascript auto_complete_contacts_path(:project_id => options[:project_id], :is_company => options[:is_company])}', '#{escape_javascript options[:select_url]}');");
    s.html_safe
  end

  def avatar_to(obj, options = { })
    # "https://avt.appsmail.ru/mail/sin23matvey/_avatar"

    options[:size] ||= "64"
    options[:width] ||= options[:size]
    options[:height] ||= options[:size]
    options.merge!({:class => "gravatar"})

    obj_icon = obj.is_a?(Contact) ? (obj.is_company ? "company.png" : "person.png") : (obj.is_a?(Deal) ? "deal.png" : "unknown.png")

    # return image_tag(obj_icon, options.merge({:plugin => "redmine_contacts"})) if Rails::env == "development"

    if obj.is_a?(Deal)
      if obj.contact
        avatar_to(obj.contact, options)
      else
        image_tag(obj_icon, options.merge({:plugin => "redmine_contacts"}))
      end
    elsif obj.is_a?(Contact) && (avatar = obj.avatar) && avatar.readable?
      avatar_url = url_for :controller => "attachments", :action => "contacts_thumbnail", :id => avatar, :size => options[:size]
      if options[:full_size]
        link_to(image_tag(avatar_url, options), :controller => 'attachments', :action => 'download', :id => avatar, :filename => avatar.filename)
      else
        image_tag(avatar_url, options)
      end
    elsif obj.respond_to?(:facebook) &&  !obj.facebook.blank?
      image_tag("https://graph.facebook.com/#{obj.facebook.gsub('.*facebook.com\/','')}/picture?type=square#{'&return_ssl_resources=1' if (request && request.ssl?)}", options)
    elsif obj.is_a?(Contact) && obj.primary_email && obj.primary_email =~ %r{^(.*)@mail.ru$}
      image_tag("http#{'s' if (request && request.ssl?)}://avt.appsmail.ru/mail/#{$1}/_avatar", options)
    elsif obj.respond_to?(:twitter) &&  !obj.twitter.blank?
      image_tag("https://api.twitter.com/1/users/profile_image?screen_name=#{obj.twitter}&size=bigger", options)
    elsif Setting.gravatar_enabled? && obj.is_a?(Contact) && obj.primary_email
      # options.merge!({:ssl => (request && request.ssl?), :default => "#{request.protocol}#{request.host_with_port}/plugin_assets/redmine_contacts/images/#{obj_icon}"})
      # gravatar(obj.primary_email.downcase, options) rescue image_tag(obj_icon, options.merge({:plugin => "redmine_contacts"}))
      avatar("<#{obj.primary_email}>", options)
    else
      image_tag(obj_icon, options.merge({:plugin => "redmine_contacts"}))
    end

  end

  def contact_tag(contact, options={})
    avatar_size = options.delete(:size) || 16
    if contact.visible? && !options[:no_link]
      contact_avatar = link_to(avatar_to(contact, :size => avatar_size), contact_path(contact, :project_id => @project), :id => "avatar")
      contact_name = link_to_source(contact, :project_id => @project)
    else
      contact_avatar = avatar_to(contact, :size => avatar_size)
      contact_name = contact.name
    end

    case options.delete(:type).to_s
    when "avatar"
      contact_avatar.html_safe
    when "plain"
      contact_name.html_safe
    else
      content_tag(:span, "#{contact_avatar} #{contact_name}".html_safe, :class => "contact")
    end
  end

  def retrieve_date_range(period)
    @from, @to = nil, nil
    case period
    when 'today'
      @from = @to = Date.today
    when 'yesterday'
      @from = @to = Date.today - 1
    when 'current_week'
      @from = Date.today - (Date.today.cwday - 1)%7
      @to = @from + 6
    when 'last_week'
      @from = Date.today - 7 - (Date.today.cwday - 1)%7
      @to = @from + 6
    when '7_days'
      @from = Date.today - 7
      @to = Date.today
    when 'current_month'
      @from = Date.civil(Date.today.year, Date.today.month, 1)
      @to = (@from >> 1) - 1
    when 'last_month'
      @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
      @to = (@from >> 1) - 1
    when '30_days'
      @from = Date.today - 30
      @to = Date.today
    when 'current_year'
      @from = Date.civil(Date.today.year, 1, 1)
      @to = Date.civil(Date.today.year, 12, 31)
    when 'last_year'
      @from = Date.civil(1.year.ago.year, 1, 1)
      @to = Date.civil(1.year.ago.year, 12, 31)
    end

    @from, @to = @from, @to + 1 if (@from && @to)

  end

  def link_to_add_phone(name)
    fields = '<p>' + label_tag(l(:field_contact_phone)) +
      text_field_tag( "contact[phones][]", '', :size => 30 ) +
      link_to_function(l(:label_crm_remove), "removeField(this)") + '</p>'
    link_to_function(name, h("addField(this, '#{escape_javascript(fields)}' )"))
  end

  def link_to_task_complete(url, bucket)
    onclick = "this.disable();"
    onclick << %Q/$("#{dom_id(pending, :name)}").style.textDecoration="line-through";/
    onclick << remote_function(:url => url, :method => :put, :with => "{ bucket: '#{bucket}' }")
  end

  def render_contact_tabs(tabs)
    if tabs.any?
      render :partial => 'common/contact_tabs', :locals => {:tabs => tabs}
    else
      content_tag 'p', l(:label_no_data), :class => "nodata"
    end
  end

  def render_contact_projects_hierarchy(projects)
    s = ''
    project_tree(projects) do |project, level|
      s << "<ul>"
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
        url = {:controller => 'contacts_projects',
               :action => 'delete',
               :related_project_id => project.id,
               :project_id => @project.id,
               :contact_id => @contact.id}

      s << "<li id='project_#{project.id}'>" + name_prefix + link_to_project(project)

      s += ' ' + link_to(image_tag('delete.png'),
                                 url,
                                 :remote => true,
                                 :method => :delete,
                                 :style => "vertical-align: middle",
                                 :class => "delete",
                                 :title => l(:button_delete)) if (projects.size > 1 && User.current.allowed_to?(:edit_contacts, project))
      s << "</li>"

      s << "</ul>"
    end
    s.html_safe
  end

  def contact_to_vcard(contact)
    return false unless ContactsSetting.vcard?

    card = Vcard::Vcard::Maker.make2 do |maker|

      maker.add_name do |name|
        name.prefix = ''
        name.given = contact.first_name.to_s
        name.family = contact.last_name.to_s
        name.additional = contact.middle_name.to_s
      end

      maker.add_addr do |addr|
        addr.preferred = true
        addr.street = contact.street1.to_s.gsub("\r\n"," ").gsub("\n"," ")
        addr.locality = contact.city.to_s
        addr.region = contact.region.to_s
        addr.postalcode = contact.postcode.to_s
        addr.country = contact.country.to_s
        addr.location = 'business'
      end

      maker.title = contact.job_title.to_s
      maker.org = contact.company.to_s
      maker.birthday = contact.birthday.to_date unless contact.birthday.blank?
      maker.add_note(contact.background.to_s.gsub("\r\n"," ").gsub("\n", ' '))

      maker.add_url(contact.website.to_s)

      contact.phones.each { |phone| maker.add_tel(phone) }
      contact.emails.each { |email| maker.add_email(email) }
    end
    avatar = contact.attachments.find_by_description('avatar')
    card = card.encode.sub("END:VCARD", "PHOTO;BASE64:" + "\n " + [File.open(avatar.diskfile).read].pack('m').to_s.gsub(/[ \n]/, '').scan(/.{1,76}/).join("\n ") + "\nEND:VCARD") if avatar && avatar.readable?

    card.to_s

  end
  def contacts_to_vcard(contacts)
    contacts.map{|c| contact_to_vcard(c) }.join("\r\n")
  end

  def contacts_to_csv(contacts)
    decimal_separator = l(:general_csv_decimal_separator)
    encoding = 'utf-8'
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  l(:field_is_company, :locale => :en),
                  l(:field_contact_first_name, :locale => :en),
                  l(:field_contact_middle_name, :locale => :en),
                  l(:field_contact_last_name, :locale => :en),
                  l(:field_contact_job_title, :locale => :en),
                  l(:field_contact_company, :locale => :en),
                  l(:field_contact_phone, :locale => :en),
                  l(:field_contact_email, :locale => :en),
                  l(:label_crm_address, :locale => :en),
                  l(:label_crm_city, :locale => :en),
                  l(:label_crm_postcode, :locale => :en),
                  l(:label_crm_region, :locale => :en),
                  l(:label_crm_country, :locale => :en),
                  l(:field_contact_skype, :locale => :en),
                  l(:field_contact_website, :locale => :en),
                  l(:field_birthday, :locale => :en),
                  l(:field_contact_tag_names, :locale => :en),
                  l(:label_crm_assigned_to, :locale => :en),
                  l(:field_contact_background, :locale => :en)
                  ]
      # Export project custom fields if project is given
      # otherwise export custom fields marked as "For all projects"
      custom_fields = ContactCustomField.order(:name)
      custom_fields.each {|f| headers << f.name}
      # Description in the last column
      csv << headers.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      # csv lines
      contacts.each do |contact|
        fields = [contact.id,
                  contact.is_company ? 1 : 0,
                  contact.first_name,
                  contact.middle_name,
                  contact.last_name,
                  contact.job_title,
                  contact.company,
                  contact.phone,
                  contact.email,
                  contact.address.to_s.gsub("\r\n"," ").gsub("\n", ' '),
                  contact.city,
                  contact.postcode,
                  contact.region,
                  contact.country,
                  contact.skype_name,
                  contact.website,
                  format_date(contact.birthday),
                  contact.tag_list.to_s,
                  contact.assigned_to ? contact.assigned_to.name : "",
                  contact.background.to_s.gsub("\r\n"," ").gsub("\n", ' ')
                  ]
        contact.custom_field_values.each {|custom_value| fields << show_value(custom_value) }
        csv << fields.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      end
    end
    export
  end

  def contacts_to_xls(contacts)
    require 'spreadsheet'

    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    headers = [ "#",
            l(:field_is_company),
            l(:field_contact_first_name),
            l(:field_contact_middle_name),
            l(:field_contact_last_name),
            l(:field_contact_job_title),
            l(:field_contact_company),
            l(:field_contact_phone),
            l(:field_contact_email),
            l(:label_crm_address),
            l(:label_crm_city),
            l(:label_crm_postcode),
            l(:label_crm_region),
            l(:label_crm_country),
            l(:field_contact_skype),
            l(:field_contact_website),
            l(:field_birthday),
            l(:field_contact_tag_names),
            l(:field_contact_background)
            ]
    custom_fields = ContactCustomField.order(:name)
    custom_fields.each {|f| headers << f.name}
    idx = 0
    row = sheet.row(idx)
    row.replace headers

    contacts.each do |contact|
      idx += 1
      row = sheet.row(idx)
      fields = [contact.id,
                  contact.is_company ? 1 : 0,
                  contact.first_name,
                  contact.middle_name,
                  contact.last_name,
                  contact.job_title,
                  contact.company,
                  contact.phone,
                  contact.email,
                  contact.address.to_s.gsub("\r\n"," ").gsub("\n", ' '),
                  contact.city,
                  contact.postcode,
                  contact.region,
                  contact.country,
                  contact.skype_name,
                  contact.website,
                  format_date(contact.birthday),
                  contact.tag_list.to_s,
                  contact.background.to_s.gsub("\r\n"," ").gsub("\n", ' ')
                  ]
      contact.custom_field_values.each {|custom_value| fields << show_value(custom_value) }
      row.replace fields
    end

    xls_stream = StringIO.new('')
    book.write(xls_stream)

    return xls_stream.string
  end

  def mail_macro(contact, message)
    message = message.gsub(/%%NAME%%/, contact.first_name)
    message = message.gsub(/%%FULL_NAME%%/, contact.name)
    message = message.gsub(/%%COMPANY%%/, contact.company) if contact.company
    message = message.gsub(/%%LAST_NAME%%/, contact.last_name) if contact.last_name
    message = message.gsub(/%%MIDDLE_NAME%%/, contact.middle_name) if contact.middle_name
    message = message.gsub(/%%DATE%%/, format_date(Date.today.to_s))

    contact.custom_field_values.each do |value|
      message = message.gsub(/%%#{value.custom_field.name}%%/, value.value.to_s)
    end
    message
  end

  def render_contact_tooltip(contact, options={})
    @cached_label_crm_company ||= l(:field_contact_company)
    @cached_label_job_title = contact.is_company ? l(:field_company_field) : l(:field_contact_job_title)
    @cached_label_phone ||= l(:field_contact_phone)
    @cached_label_email ||= l(:field_contact_email)

    emails = contact.emails.any? ? contact.emails.map{|email| "<span class=\"email\" style=\"white-space: nowrap;\">#{mail_to email}</span>"}.join(', ') : ''
    phones = contact.phones.any? ? contact.phones.map{|phone| "<span class=\"phone\" style=\"white-space: nowrap;\">#{phone}</span>"}.join(', ') : ''

    s = link_to_contact(contact, options) + "<br /><br />".html_safe
    s <<  "<strong>#{@cached_label_job_title}</strong>: #{contact.job_title}<br />".html_safe unless contact.job_title.blank?
    s <<  "<strong>#{@cached_label_crm_company}</strong>: #{link_to(contact.contact_company.name, {:controller => 'contacts', :action => 'show', :id => contact.contact_company.id })}<br />".html_safe if !contact.contact_company.blank? && !contact.is_company
    s <<  "<strong>#{@cached_label_email}</strong>: #{emails}<br />".html_safe if contact.emails.any?
    s <<  "<strong>#{@cached_label_phone}</strong>: #{phones}<br />".html_safe if contact.phones.any?
    s
  end

  def link_to_contact(contact, options={})
    s = ''
    html_options = {}
    html_options = {:class => 'icon icon-vcard'} if options[:icon] == true
    s << avatar_to(contact, :size => "16") if options[:avatar] == true
 		s << link_to_source(contact, html_options)

 		s << "(#{contact.job_title}) " if (options[:job_title] == true) && !contact.job_title.blank?
		s << " #{l(:label_crm_at_company)} " if (options[:job_title] == true) && !(contact.job_title.blank? or contact.company.blank?)
		if (options[:company] == true) and contact.contact_company
			s << link_to(contact.contact_company.name, {:controller => 'contacts', :action => 'show', :id => contact.contact_company.id })
		else
			h contact.company
		end
 		s << "(#{l(:field_contact_tag_names)}: #{contact.tag_list.join(', ')}) " if (options[:tag_list] == true) && !contact.tag_list.blank?
    s.html_safe
  end

  def tagsedit_with_source_for(field_id, url)
    s = ""
    unless @heads_for_tagsedit_included
      s << javascript_include_tag(:"tag-it", :plugin => 'redmine_contacts')
      s << stylesheet_link_tag(:"jquery.tagit.css", :plugin => 'redmine_contacts')
      @heads_for_tagsedit_included = true
    end
    s << javascript_tag("$('#{field_id}').tagit({
        tagSource: function(search, showChoices) {
          var that = this;
          $.ajax({
          url: '#{url}',
          data: {q: search.term},
          success: function(choices) {
            showChoices(that._subtractArray(jQuery.parseJSON(choices), that.assignedTags()));
          }
          });
        },
        allowSpaces: true,
        placeholderText: '#{l(:label_crm_add_tag)}',
        caseSensitive: false,
        removeConfirmation: true
      });")
    s.html_safe
  end

  def tagsedit_for(field_id, available_tags='')
    s = ""
    unless @heads_for_tagsedit_included
      s << javascript_include_tag(:"tag-it", :plugin => 'redmine_contacts')
      s << stylesheet_link_tag(:"jquery.tagit.css", :plugin => 'redmine_contacts')
      @heads_for_tagsedit_included = true
    end

    s << javascript_tag("$('#{field_id}').tagit({
        availableTags: ['#{available_tags}'],
        allowSpaces: true,
        placeholderText: '#{l(:label_crm_add_tag)}',
        caseSensitive: false,
        removeConfirmation: true
      });")
    s.html_safe
  end

  def set_flash_from_bulk_contact_save(contacts, unsaved_contact_ids)
    if unsaved_contact_ids.empty?
      flash[:notice] = l(:notice_successful_update) unless contacts.empty?
    else
      flash[:error] = l(:notice_failed_to_save_contacts,
                        :count => unsaved_contact_ids.size,
                        :total => contacts.size,
                        :ids => '#' + unsaved_contact_ids.join(', #'))
    end
  end

end
