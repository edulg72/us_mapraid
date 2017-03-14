class PU < ActiveRecord::Base
  self.table_name = 'vw_pu'

  belongs_to :citymapraid, foreign_key: 'city_id', class_name: 'CityMapraid'

  scope :national, -> { where("city_id is not null") }
  scope :editable, -> { where("not staff")}
  scope :blocked, -> { where("staff")}

  def permalink
    "https://www.waze.com/editor/?env=#{I18n.t('env')}\&zoom=7\&lat=#{self.latitude}\&lon=#{self.longitude}\&showpur=#{self.id}\&endshow"
  end
end
