class AddIsNoteAndNoteScopeToNews < ActiveRecord::Migration
  def change
    add_column :news, :is_note, :boolean, :default => false
    add_column :news, :note_scope, :string
  end
end
