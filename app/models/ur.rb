class UR < ActiveRecord::Base
  self.table_name = 'vw_ur'

  belongs_to :commentator, foreign_key: 'last_comment_by', class_name: 'User'
  belongs_to :operator, foreign_key: 'resolved_by', class_name: 'Editor'
  belongs_to :citymapraid, foreign_key: 'city_id'

  scope :without_comments, -> { where("comments = 0")}
  scope :with_answer, -> { where("comments > 0 and last_comment_by = -1")}
  scope :without_answer, -> { where("comments > 0 and last_comment_by > 0")}
  scope :open, -> { where("resolved_on is null")}
  scope :closed, -> { where("resolved_on is not null")}

  def permalink
    "https://www.waze.com/editor/?env=#{I18n.t('env')}&zoom=7\&lat=#{self.latitude}\&lon=#{self.longitude}\&mapUpdateRequest=#{self.id}"
  end
end
