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
  scope :unverified_speed, -> {where('((fwddirection and fwdmaxspeedunverified) or (revdirection and revmaxspeedunverified))')}
  scope :low_lock, -> {where('(roadtype in (3,4,6,7,15,18) and lock is null) or (roadtype = 3 and lock < 5) or (roadtype = 4 and lock < 4) or (roadtype = 18 and lock < 2) or (roadtype = 6 and lock < 5) or (roadtype = 7 and lock < 3) or (roadtype = 15 and lock < 5)')}

  def permalink(server = 'ROW')
    env = {'ROW' => 'row', 'NA' => 'usa'}
    "https://www.waze.com/editor/?env=#{env[server]}&zoom=5&lat=#{latitude}&lon=#{longitude}&segments=#{id}"
  end

  def location
    "#{(street_id.nil? ? I18n.t('no-street') : (street.isempty ? I18n.t('no-street') : street.name.to_s) + ', ' + (street.city_id.nil? ? I18n.t('no-city') : (street.city.isempty ? I18n.t('no-city') : street.city.name.to_s) + ', ' + (street.city.state_id.nil? ? I18n.t('no-state') : street.city.state.name.to_s)))}"
  end
end
