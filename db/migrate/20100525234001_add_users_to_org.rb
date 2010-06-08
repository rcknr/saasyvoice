class AddUsersToOrg < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.references :organization
    end
  end

  def self.down
    change_table :users do |t|
      t.remove_references :organization
    end
  end
end
