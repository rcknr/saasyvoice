class PhoneNumber < ActiveRecord::Base
  belongs_to :organization
  has_many :extensions, :autosave=>true
  
  validates_presence_of :number
  #validates_uniqueness_of :number
 
  def next_extension
    ext = Extension.maximum(:number, :conditions => ['phone_number_id = ?', id])
    ext.to_i + 1
  end
  
end
