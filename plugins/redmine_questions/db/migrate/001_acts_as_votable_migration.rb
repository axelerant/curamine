class ActsAsVotableMigration < ActiveRecord::Migration
  def self.up
    unless table_exists? :votes
      create_table :votes do |t|

        t.references :votable, :polymorphic => true
        t.references :voter, :polymorphic => true

        t.boolean :vote_flag

        t.timestamps
      end

      add_index :votes, [:votable_id, :votable_type]
      add_index :votes, [:voter_id, :voter_type]
    end

    add_column :messages, :cached_votes_total, :integer, :default => 0
    add_column :messages, :cached_votes_up, :integer, :default => 0
    add_column :messages, :cached_votes_down, :integer, :default => 0
    add_index  :messages, :cached_votes_total
    add_index  :messages, :cached_votes_up
    add_index  :messages, :cached_votes_down    
  end

  def self.down
    drop_table :votes
    remove_column :messages, :cached_votes_total
    remove_column :messages, :cached_votes_up
    remove_column :messages, :cached_votes_down
  end
end
