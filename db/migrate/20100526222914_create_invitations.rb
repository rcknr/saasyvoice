class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.references :organization
      t.string :email
      t.boolean :expired
      t.timestamps
    end
  end

  def self.down
    drop_table :invitations
  end
end
