class LocationMigration < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
			t.references :app
			t.string :directory
			t.string :ip	
      t.timestamps
    end
 
  end

  def self.down
    drop_table :locations
  end
end
