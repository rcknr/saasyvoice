class CreateOrganizations < ActiveRecord::Migration
  def self.up
    create_table :organizations do |t|
      t.string :name
      t.string :domain
      t.boolean :enabled

      t.timestamps
    end
  end

  def self.down
    drop_table :organizations
  end
end
