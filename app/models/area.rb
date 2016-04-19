class Area < ActiveRecord::Base
  self.table_name = 'areas_mapraid'

  has_many :cities, class_name: 'CityMapraid'
  has_many :segments, through: :cities

  scope :mapraid, -> {where(id: 1814)}
  scope :others, -> {where('id not in (1,2,3)')}
  scope :states, -> {where('id in (4,5)')}
end
