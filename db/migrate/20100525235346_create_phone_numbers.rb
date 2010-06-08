class CreatePhoneNumbers < ActiveRecord::Migration
  def self.up
    create_table :phone_numbers do |t|
      t.string :number
      t.references :organization
      t.has_many :extensions
      t.timestamps
    end
  end

  def self.down
    drop_table :phone_numbers
  end
end
