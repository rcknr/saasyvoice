class AddOrganizaton2lo < ActiveRecord::Migration
  def self.up
    change_table :organizations do |t|
      t.boolean :from_marketplace
    end    
  end

  def self.down
    change_table :organizations do |t|
      t.remove :from_marketplace
    end    
  end
end
