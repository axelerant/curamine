module RedmineSilencer
  class IssueHooks < Redmine::Hook::Listener
    def controller_issues_edit_before_save(context)
      update_journal_notify(context[:params], context[:journal])
    end

    def controller_issues_bulk_edit_before_save(context)
      update_journal_notify(context[:params], context[:issue].current_journal)
    end

    private

    def update_journal_notify(params, journal)
      if journal && params && params[:suppress_mail] == '1'
        if User.current.allowed_to?(:suppress_mail_notifications,
                                    journal.project)
          journal.notify = false
        else
          # what?
        end
      end
    end
  end
end
