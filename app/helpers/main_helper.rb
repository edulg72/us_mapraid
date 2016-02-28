module MainHelper
  def roadtype_name(roadtype)
    case roadtype
      when 3
        t("freeway")
      when 6
        t("major-highway")
      when 7
        t("minor-highway")
      when 4
        t("ramp")
      when 2
        t("primary-street")
      when 1
        t("Street")
      when 8
        t("dirt-road")
      when 20
        t("parking-lot-road")
      when 17
        t("private-road")
      when 5
        t("walking-trail")
      when 10
        t("pedestrian-boardwalk")
      when 16
        t("stairway")
      when 18
        t("railroad")
      when 19
        t("runway")
      when 15
        t("ferry")
      else
        t('unknown')
    end
  end
end
