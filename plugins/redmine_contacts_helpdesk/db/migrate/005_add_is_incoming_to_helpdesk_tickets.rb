class AddIsIncomingToHelpdeskTickets < ActiveRecord::Migration
  def change
    add_column :helpdesk_tickets, :is_incoming, :boolean, :default => true
  end
end
