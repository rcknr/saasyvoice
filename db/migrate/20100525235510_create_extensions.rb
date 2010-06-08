class CreateExtensions < ActiveRecord::Migration
  def self.up
    create_table :extensions do |t|
      t.string :number
      t.string :forward_to
      t.belongs_to :phone_number
      t.belongs_to :user
      t.has_many :message

      t.timestamps
    end
  end

  def self.down
    drop_table :extensions
  end
end
