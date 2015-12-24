class State < ActiveRecord::Base
  has_many :cities
  has_many :segments, through: :cities
  belongs_to :country
end
