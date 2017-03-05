#!/usr/bin/ruby
# encoding: utf-8
#
# scan_segments.rb
# Popula tabelas em uma base PostgreSQL com os dados dos segmentos de uma região.
# (c)2015-2016 Eduardo Garcia <edulg72@gmail.com>
#
# Usage:
# scan_segments.rb <usuario> <senha> <longitude oeste> <latitude norte> <longitude leste> <latitude sul> <passo em graus*>
#
# * Define o tamanho dos quadrados das áreas para análise. Em regiões muito populosas usar valores pequenos para não sobrecarregar o server.

require 'mechanize'
require 'pg'
require 'json'

if ARGV.size < 7
  puts "Usage: ruby scan_segments.rb <user> <password> <west longitude> <north latitude> <east longitude> <south latitude> <step>"
  exit
end

USER = ARGV[0]
PASS = ARGV[1]
LongOeste = ARGV[2].to_f
LatNorte = ARGV[3].to_f
LongLeste = ARGV[4].to_f
LatSul = ARGV[5].to_f
Passo = ARGV[6].to_f

puts "Starting analysis on [#{LongOeste} #{LatNorte}] - [#{LongLeste} #{LatSul}]"

agent = Mechanize.new
begin
  page = agent.get "https://www.waze.com/Descartes-live/app/Session"
rescue Mechanize::ResponseCodeError
  csrf_token = agent.cookie_jar.jar['www.waze.com']['/']['_csrf_token'].value
end
login = agent.post('https://www.waze.com/login/create', {"user_id" => USER, "password" => PASS}, {"X-CSRF-Token" => csrf_token})

db = PG::Connection.new(:hostaddr => ENV['POSTGRESQL_DB_HOST'], :dbname => 'us_mapraid', :user => ENV['POSTGRESQL_DB_USERNAME'], :password => ENV['POSTGRESQL_DB_PASSWORD'])
#db.prepare('insere_usuario','insert into users (id, username, rank) values ($1,$2,$3)')
#db.prepare('insere_rua','insert into streets (id,name,city_id,isempty) values ($1,$2,$3,$4)')
#db.prepare('insere_cidade','insert into cities (id,name,state_id,isempty) values ($1,$2,$3,$4)')
#db.prepare('insere_estado','insert into states (id,name,country_id) values ($1,$2,$3)')
#db.prepare('insere_segmento',"insert into segments (id,longitude,latitude,roadtype,level,lock,last_edit_by,last_edit_on,street_id,length,connected,fwddirection,revdirection,fwdmaxspeed,revmaxspeed) values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)")

db.exec_params('delete from streets where id in (select street_id from segments where longitude between $1 and $2 and latitude between $3 and $4)',[LongOeste,LongLeste,LatSul,LatNorte])
db.exec_params('delete from segments where longitude between $1 and $2 and latitude between $3 and $4',[LongOeste,LongLeste,LatSul,LatNorte])
db.exec('vacuum streets')
db.exec('vacuum segments')

@users = {}
@states = {}
@cities = {}
@streets = {}
@segments = {}

def busca(db,agent,longOeste,latNorte,longLeste,latSul,passo,exec)
  lonIni = longOeste
  while lonIni < longLeste do
    lonFim = [(lonIni + passo).round(13) , longLeste].min
    lonFim = lonIni + passo if (lonFim - lonIni) < (passo / 2)
    latIni = latNorte
    while latIni > latSul do
      latFim = [(latIni - passo).round(13), latSul].max
      latFim = latIni - passo if (latIni - latFim) < (passo / 2)
      area = [lonIni, latIni, lonFim, latFim]

      begin
        wme = agent.get "https://www.waze.com/Descartes-live/app/Features?roadTypes=1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C10%2C15%2C16%2C17%2C18%2C19%2C20&zoom=3&bbox=#{area.join('%2C')}"

        json = JSON.parse(wme.body)

        # Coleta os usuários que editaram na área
        json['users']['objects'].each {|u| @users[u['id']] = "#{u['id']},\"#{u['userName']}\",#{u['rank']+1}\n" if not @users.has_key?(u['id']) }

        # Coleta os nomes dos estados na área
        json['states']['objects'].each {|s| @states[s['id']] = "#{s['id']},\"#{s['name']}\",#{s['countryID']}\n" if not @states.has_key?(s['id']) }

        # Coleta os nomes das cidades na área
        json['cities']['objects'].each {|c| @cities[c['id']] = "#{c['id']},\"#{c['name']}\",#{c['stateID']},#{c['isEmpty'] ? 'TRUE' : 'FALSE' }\n" if not @cities.has_key?(c['id']) }

        # Coleta os nomes das ruas na área
        json['streets']['objects'].each {|s| @streets[s['id']] = "#{s['id']},\"#{s['name']}\",#{s['cityID']},#{s['isEmpty'] ? 'TRUE' : 'FALSE' }\n" if not @streets.has_key?(s['id']) }

        # Coleta os dados sobre os segmentos na area
        json['segments']['objects'].each do |s|
          (longitude, latitude) = s['geometry']['coordinates'][(s['geometry']['coordinates'].size / 2)]
          @segments[s['id']] = "#{s['id']},#{longitude},#{latitude},#{s['roadType']},#{s['level']},#{(s['lockRank'].nil? ? '' : s['lockRank'] + 1)},#{(s['updatedOn'].nil? ? s['createdBy'] : s['updatedBy'])},#{(s['updatedOn'].nil? ? Time.at(s['createdOn']/1000) : Time.at(s['updatedOn']/1000))},#{s['primaryStreetID']},#{s['length']},#{((s['fwdDirection'] and json['connections'].has_key?(s['id'].to_s + 'f')) or (s['revDirection'] and json['connections'].has_key?(s['id'].to_s + 'r'))) ? 'TRUE' : 'FALSE' },#{s['fwdDirection']},#{s['revDirection']},#{s['fwdMaxSpeed']},#{s['revMaxSpeed']},#{(s['junctionID'].nil? ? 'FALSE' : 'TRUE')},#{s['streetIDs'].size > 0},#{s['validated']},#{s['fwdToll'] or s['revToll']},#{s['flags']}\n" if not @segments.has_key?(s['id'])
        end

      rescue Mechanize::ResponseCodeError, NoMethodError
       # Caso o problema tenha sido no tamanho do pacote de resposta, divide a area em 4 pedidos menores (limitado a 3 reducoes)
        if exec < 3
          busca(db,agent,area[0],area[1],area[2],area[3],(passo/2),(exec+1))
        else
          puts "[#{Time.now.strftime('%d/%m/%Y %H:%M:%S')}] - ResponseCodeError em #{area}"
        end
      rescue JSON::ParserError
        if exec < 3
          sleep(5)
          busca(db,agent,area[0],area[1],area[2],area[3],passo,(exec+1))
        else
          puts "Erro JSON em #{area}"
        end
      end

      latIni = latFim
    end
    lonIni = lonFim
  end
end

busca(db,agent,LongOeste,LatNorte,LongLeste,LatSul,Passo,1)

db.exec("delete from users where id in (#{@users.keys.join(',')})") if @users.keys.size > 0
db.copy_data('COPY users (id,username,rank) FROM STDIN CSV') do
  @users.each_value {|u| db.put_copy_data u}
end
db.exec('vacuum users')

db.exec("delete from states where id in (#{@states.keys.join(',')})") if @states.keys.size > 0
db.copy_data('COPY states (id,name,country_id) FROM STDIN CSV') do
  @states.each_value {|s| db.put_copy_data s}
end
db.exec('vacuum states')

db.exec("delete from cities where id in (#{@cities.keys.join(',')})") if @cities.keys.size > 0
db.copy_data('COPY cities (id,name,state_id,isempty) FROM STDIN CSV') do
  @cities.each_value {|c| db.put_copy_data c}
end
db.exec('vacuum cities')

db.exec("delete from streets where id in (#{@streets.keys.join(',')})") if @streets.keys.size > 0
#@streets.each_value {|s| puts s}
db.copy_data('COPY streets (id,name,city_id,isempty) FROM STDIN CSV') do
  @streets.each_value {|s| db.put_copy_data s}
end
db.exec('vacuum streets')

db.exec("delete from segments where id in (#{@segments.keys.join(',')})") if @segments.keys.size > 0
db.copy_data('COPY segments (id, longitude, latitude, roadtype, level, lock, last_edit_by, last_edit_on, street_id, length, connected, fwddirection, revdirection, fwdmaxspeed, revmaxspeed, roundabout, alt_names, validated, toll, flags) FROM STDIN CSV') do
  @segments.each_value {|s| db.put_copy_data s}
end

db.exec('vacuum segments')
