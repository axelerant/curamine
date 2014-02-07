module PublicTicketsHelper
  include HelpdeskHelper

  def authoring_public(journal, options={})
    if journal.journal_message && journal.journal_message.from_address
      l(options[:label] || :label_added_time_by, :author => mail_to(journal.journal_message.contact_email), :age => ticket_time_tag(journal.created_on)).html_safe
    else
      l(options[:label] || :label_added_time_by, :author => journal.user.name, :age => ticket_time_tag(journal.created_on)).html_safe
    end
  end

  def ticket_time_tag(time)
    text = distance_of_time_in_words(Time.now, time)
    content_tag('acronym', text, :title => format_time(time))
  end

  def link_to_attachments_with_hash(container, options = {})
    options.assert_valid_keys(:author, :thumbnails)

    if container.attachments.any?
      options = {:deletable => container.attachments_deletable?, :author => true}.merge(options)
      render :partial => 'attachment_links',
             :locals => {:attachments => container.attachments, :options => options, :thumbnails => (options[:thumbnails] && Setting.thumbnails_enabled?)}
    end
  end

  def link_to_attachment_with_hash(attachment, options={})
    text = options.delete(:text) || attachment.filename
    route_method = options.delete(:download) ? :hashed_download_named_attachment_path : :hashed_named_attachment_path
    html_options = options.slice!(:only_path)
    url = send(route_method, attachment, @ticket.id, @ticket.token, attachment.filename, options)
    link_to text, url, html_options
  end

end