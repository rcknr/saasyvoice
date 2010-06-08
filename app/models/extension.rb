class Extension < ActiveRecord::Base
  has_many :messages
  belongs_to :phone_number
  belongs_to :user
  
  validates_uniqueness_of :number, :scope => :phone_number_id
  attr_accessible :forward_to
  
end
