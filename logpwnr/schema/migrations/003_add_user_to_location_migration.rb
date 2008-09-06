class AddUserToLocationMigration < ActiveRecord::Migration
  def self.up
		add_column :locations, :user, :string
  end

  def self.down
		remove_column :locations, :user
  end
end
