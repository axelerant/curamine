class CreateContactJournals < ActiveRecord::Migration
  def self.up
    create_table :contact_journals do |t|
      t.references :contact
      t.references :journal
      t.string :email
      t.boolean :is_incoming
      t.timestamps
    end
    add_index :contact_journals, [:journal_id, :contact_id]
  end

  def self.down
    drop_table :contact_journals
  end
end

