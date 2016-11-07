class CityMapraid < ActiveRecord::Base
  self.table_name = 'cities_mapraid'
  self.primary_key = 'gid'

  belongs_to :area
  belongs_to :city, foreign_key: :city_id, class_name: 'City'
  has_many :segments, foreign_key: :city_id
  has_many :urs, foreign_key: :city_id, class_name: 'UR'
  has_many :mps, foreign_key: :city_id, class_name: 'MP'
  has_many :pus, foreign_key: :city_id, class_name: 'PU'

  def color
    d = self.segments.disconnected.count
    if d == 0
      c = "#0F0"
    elsif d < 20
      c = "#FF0"
    else
      c = '#F00'
    end
    return c
  end
end
