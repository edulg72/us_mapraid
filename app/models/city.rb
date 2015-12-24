class City < ActiveRecord::Base
  has_many :streets
  has_many :segments, through: :streets
  has_one :city_mapraid, foreign_key: :city_id
  belongs_to :state
end
