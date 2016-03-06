class Update < ActiveRecord::Base
  scope :states, -> {where("object in ('AG','DF')")}
end
