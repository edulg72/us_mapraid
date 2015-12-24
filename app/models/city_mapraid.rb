class CityMapraid < ActiveRecord::Base
  self.table_name = 'cities_mapraid'
  
  belongs_to :area
  belongs_to :city, foreign_key: :city_id, class_name: 'City'
  has_many :segments, through: :city 
  
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
