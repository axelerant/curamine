class CreateProjectDailyStatusSettings < ActiveRecord::Migration
  def change
    create_table :daily_status_settings do |t|
      t.integer :project_id, :null => false
    end
  end
end