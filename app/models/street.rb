class Street < ActiveRecord::Base
  belongs_to :city
  has_many :segments

  def segment_ids
    segs = []
    self.segments.each {|s| segs << s.id}
    segs.join(',')
  end
end
