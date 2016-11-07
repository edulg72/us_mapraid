class Area < ActiveRecord::Base
  self.table_name = 'areas_mapraid'

  has_many :cities, class_name: 'CityMapraid'
  has_many :segments, through: :cities
  has_many :urs, through: :cities
  has_many :mps, through: :cities
  has_many :pus, through: :cities

end
