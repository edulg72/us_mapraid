class MainController < ApplicationController

  def index
    @areas = CityMapraid.all
    @update = Update.maximum('updated_at')
    @segments = Segment.all
    @pu = PU.all
    @ur = UR.all
    @mp = MP.all
    @nav = [{ t('nav-first-page') => '/'}]
  end

  def segments
    @area = CityMapraid.find(params['id'])
    @update = Update.find('segments')
    @nav = [{@area.name => "/segments/#{@area.gid}"},{ t('nav-first-page') => '/'}]
  end

  def requests
    @area = CityMapraid.find(params[:id])
    @upd_ur = Update.find('ur')
    @upd_pu = Update.find('pu')
    @nav = [{@area.name => "/requests/#{@area.gid}"},{ t('nav-first-page') => '/'}]
  end

  def staff
    @places = PU.blocked
    @upd_pu = Update.find('pu')
    @nav = [{'Staff' => '#'},{ t('nav-first-page') => '/'}]
  end
end
