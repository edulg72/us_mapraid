class Segment < ActiveRecord::Base
  self.table_name = 'vw_segments'
  
  belongs_to :editor, foreign_key: :last_edit_by, class_name: 'User'
  belongs_to :street 
  belongs_to :city, foreign_key: :city_id, class_name: 'CityMapraid'

  scope :drivable, -> {where('roadtype in (1,2,3,4,6,7,8,15,17,20)')}
  scope :important, -> {where('roadtype in (3,4,6,7)')}
  scope :disconnected, -> {where('not connected')}
  scope :no_name, -> {where('street_id is null')}
  scope :with_speed, -> {where('(not fwddirection or fwdmaxspeed is not null) and (not revdirection or revmaxspeed is not null)')}
  scope :without_speed, -> {where('((fwddirection and fwdmaxspeed is null) or (revdirection and revmaxspeed is null))')}
end
