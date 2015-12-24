class MainController < ApplicationController

  def index
    @areas = Area.mapraid
    @nav = [{ t('nav-first-page') => '/'}]
  end
  
  def segments
    @city = CityMapraid.find(params['id'])
    @update = Update.find('segments')
    @nav = [{@city.name => "/segments/#{@city.gid}"},{ t('nav-first-page') => '/'}]
  end

  def admin
    @areas = Area.others
    @nav = [{ t('nav-first-page') => '/'}]
    render :index
  end
end
