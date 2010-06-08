class AddUserOpenid < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.string :openid
    end    
  end

  def self.down
    change_table :users do |t|
      t.remove :openid
    end    
  end
end
