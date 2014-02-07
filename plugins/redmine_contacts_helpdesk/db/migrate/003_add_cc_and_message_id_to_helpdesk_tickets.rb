class AddCcAndMessageIdToHelpdeskTickets < ActiveRecord::Migration
  def change
    add_column :helpdesk_tickets, :cc_address, :string
    add_column :helpdesk_tickets, :message_id, :string
    
    add_column :journal_messages, :message_id, :string
  end
end
