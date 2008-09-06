class AppMigration < ActiveRecord::Migration
  def self.up
    create_table :apps do |t|
			t.string :name
			t.string :summary
			t.date :last_harvested	
      t.timestamps
    end
 
  end

  def self.down
    drop_table :apps
  end
end
