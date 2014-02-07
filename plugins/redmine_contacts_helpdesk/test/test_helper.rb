require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# Engines::Testing.set_fixture_path

module RedmineHelpdesk

  module TestHelper
    HELPDESK_FIXTURES_PATH = File.dirname(__FILE__) + '/fixtures/helpdesk_mailer'

    def submit_email(filename, options={})
      raw = IO.read(File.join(HELPDESK_FIXTURES_PATH, filename))
      MailHandler.receive(raw, options)
    end

    def submit_helpdesk_email(filename, options={})
      raw = IO.read(File.join(HELPDESK_FIXTURES_PATH, filename))
      HelpdeskMailer.receive(raw, options)
    end


    def last_email
      mail = ActionMailer::Base.deliveries.last
      assert_not_nil mail
      mail
    end
  end

  class TestCase

    def self.prepare
      Role.find(1, 2, 3, 4).each do |r|
        r.permissions << :view_contacts
        r.save
      end
      Role.find(1, 2).each do |r|
        r.permissions << :edit_contacts
        r.save
      end

      Role.find(1, 2, 3).each do |r|
        r.permissions << :view_deals
        r.save
      end
      Project.find(1, 2, 3, 4).each do |project|
        EnabledModule.create(:project => project, :name => 'contacts')
        EnabledModule.create(:project => project, :name => 'contacts_helpdesk')
      end
    end

  end
end