class MP < ActiveRecord::Base
  self.table_name = 'vw_mp'

  belongs_to :operator, foreign_key: 'resolved_by', class_name: 'Editor'
  belongs_to :citymapraid, foreign_key: 'city_id'

  scope :national, -> { where("city_id is not null") }
  scope :open, -> { where("resolved_on is null")}
  scope :closed, -> { where("resolved_on is not null")}

  def permalink
    "https://www.waze.com/editor/?env=#{I18n.t('env')}\&zoom=7\&lat=#{self.latitude}\&lon=#{self.longitude}\&mapProblem=#{self.id}"
  end
end
