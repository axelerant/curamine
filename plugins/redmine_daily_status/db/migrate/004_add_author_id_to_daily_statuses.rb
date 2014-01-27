class AddAuthorIdToDailyStatuses < ActiveRecord::Migration
  def change
    add_column :daily_statuses, :author_id, :integer, :after => :is_email_sent
  end
end
