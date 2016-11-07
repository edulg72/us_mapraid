class PU < ActiveRecord::Base
  self.table_name = 'vw_pu'

  belongs_to :citymapraid, foreign_key: 'city_id', class_name: 'CityMapraid'

  scope :national, -> { where("city_id is not null") }
  scope :editable, -> { where("not staff")}
  scope :blocked, -> { where("staff")}
end
