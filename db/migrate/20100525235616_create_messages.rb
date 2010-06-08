class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.belongs_to :extension
      t.string :guid
      t.string :from
      t.string :url
      t.integer :duration
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
