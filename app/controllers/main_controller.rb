class MainController < ApplicationController

  def index
    @areas = Area.mapraid
    @update = Update.maximum('updated_at')
    @nav = [{ t('nav-first-page') => '/'}]
  end

  def segments
    @area = CityMapraid.find(params['id'])
    begin
      @update = Update.find(@area.area.abbreviation)
    rescue
      @update = Update.find('segments')
    end
    @nav = [{@area.name => "/segments/#{@area.gid}"},{@area.area.name => "/segments_area/#{@area.area.id}"},{ t('nav-first-page') => '/'}]
  end

  def segments_area
    @area = Area.find(params[:id])
    begin
      @update = Update.find(@area.abbreviation)
    rescue
      @update = Update.find('segments')
    end
    @nav = [{@area.name => "#"},{ t('nav-first-page') => '/'}]
    render :segments
  end
end
