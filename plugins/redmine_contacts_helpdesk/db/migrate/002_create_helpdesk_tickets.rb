class CreateHelpdeskTickets < ActiveRecord::Migration
  def self.up
    create_table :helpdesk_tickets do |t|
      t.references :contact
      t.references :issue
      t.integer :source, :null => false, :default => HelpdeskTicket::HELPDESK_EMAIL_SOURCE
      t.string :from_address
      t.string :to_address
      t.datetime :ticket_date
    end
    add_index :helpdesk_tickets, [:issue_id, :contact_id]

    rename_table :contact_journals, :journal_messages

    change_table :journal_messages do |t|
      t.remove :created_at, :updated_at
      t.integer :source, :null => false, :default => HelpdeskTicket::HELPDESK_EMAIL_SOURCE
      t.string :from_address
      t.string :to_address
      t.string :bcc_address
      t.string :cc_address
      t.datetime :message_date
    end

    JournalMessage.where(:is_incoming => true).update_all("from_address = email")
    JournalMessage.where(:is_incoming => false).update_all("to_address = email")

    remove_column :journal_messages, :email
    Attachment.where(:container_type => 'ContactJournal').update_all(:container_type => 'JournalMessage')

  end

  def self.down
    Attachment.where(:container_type => 'JournalMessage').update_all(:container_type => 'ContactJournal')
    drop_table :helpdesk_tickets
    add_column :journal_messages, :email, :string

    JournalMessage.where(:is_incoming => true).update_all("email = from_address")
    JournalMessage.where(:is_incoming => false).update_all("email = to_address")

    change_table :journal_messages do |t|
      t.timestamps
      t.remove :source, :from_address, :to_address, :bcc_address, :cc_address, :message_date
    end

    rename_table :journal_messages, :contact_journals

  end
end

