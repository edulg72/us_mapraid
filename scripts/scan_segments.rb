#!/usr/bin/ruby
# encoding: utf-8
#
# scan_segments.rb
# Popula tabelas em uma base PostgreSQL com os dados dos segmentos de uma região.
# (c)2015 Eduardo Garcia <edulg72@gmail.com>
#
# Usage:
# busca_segments.rb <usuario> <senha> <longitude oeste> <latitude norte> <longitude leste> <latitude sul> <passo em graus*>
#
# * Define o tamanho dos quadrados das áreas para análise. Em regiões muito populosas usar valore pequenos para não sobrecarregar o server.

require 'mechanize'
require 'pg'
require 'json'

if ARGV.size < 7
  puts "Usage: ruby scan_segments.rb <user> <password> <west longitude> <north latitude> <east longitude> <south latitude> <step> [transactions per analyze]"
  exit
end

USER = ARGV[0]
PASS = ARGV[1]
LongOeste = ARGV[2].to_f
LatNorte = ARGV[3].to_f
LongLeste = ARGV[4].to_f
LatSul = ARGV[5].to_f
Passo = ARGV[6].to_f
LimitTransactions = (ARGV.size > 7 ? ARGV[7].to_i : 100)

puts "Starting analysis on [#{LongOeste} #{LatNorte}] - [#{LongLeste} #{LatSul}]"

agent = Mechanize.new
begin
  page = agent.get "https://www.waze.com/row-Descartes-live/app/Session"
rescue Mechanize::ResponseCodeError
  csrf_token = agent.cookie_jar.jar['www.waze.com']['/']['_csrf_token'].value
end
login = agent.post('https://www.waze.com/login/create', {"user_id" => USER, "password" => PASS}, {"X-CSRF-Token" => csrf_token})

db = PG::Connection.new(:hostaddr => ENV['POSTGRESQL_DB_HOST'], :dbname => ENV['DB_NAME'], :user => ENV['POSTGRESQL_DB_USERNAME'], :password => ENV['POSTGRESQL_DB_PASSWORD'])
db.prepare('insere_usuario','insert into users (id, username, rank) values ($1,$2,$3)')
db.prepare('insere_rua','insert into streets (id,name,city_id,isempty) values ($1,$2,$3,$4)')
db.prepare('insere_cidade','insert into cities (id,name,state_id,isempty) values ($1,$2,$3,$4)')
db.prepare('insere_estado','insert into states (id,name,country_id) values ($1,$2,$3)')
db.prepare('insere_segmento',"insert into segments (id,longitude,latitude,roadtype,level,lock,last_edit_by,last_edit_on,street_id,length,connected,fwddirection,revdirection,fwdmaxspeed,revmaxspeed) values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)") 

db.exec_params('delete from streets where id in (select street_id from segments where longitude between $1 and $2 and latitude between $3 and $4)',[LongOeste,LongLeste,LatSul,LatNorte])
db.exec_params('delete from segments where longitude between $1 and $2 and latitude between $3 and $4',[LongOeste,LongLeste,LatSul,LatNorte])
db.exec('vacuum')

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
      puts "=> [(#{lonIni} #{latIni}),(#{lonFim} #{latFim})]"

      begin
        wme = agent.get "https://www.waze.com/row-Descartes-live/app/Features?roadTypes=1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C10%2C15%2C16%2C17%2C18%2C19%2C20&zoom=3&bbox=#{area.join('%2C')}"

        json = JSON.parse(wme.body)

        # Coleta os usuários que editaram na área
        json['users']['objects'].each do |u|
          usu = db.exec_params('select rank from users where id = $1',[u['id']])
          if usu.ntuples == 0 or usu[0]['rank'].to_i != (u['rank']+1)
            db.exec_params('delete from users where id = $1',[u['id']]) if usu.ntuples > 0
            db.exec_prepared('insere_usuario', [u['id'],u['userName'],u['rank']+1])
          end
        end
    
        # Coleta os nomes dos estados na área
        json['states']['objects'].each do |s|
          if db.exec_params('select id from states where id = $1',[s['id']]).ntuples == 0
            db.exec_prepared('insere_estado', [s['id'],s['name'],s['countryID']])
          end
        end
    
        # Coleta os nomes das cidades na área
        json['cities']['objects'].each do |s|
          if db.exec_params('select id from cities where id = $1',[s['id']]).ntuples == 0
            db.exec_prepared('insere_cidade', [s['id'],s['name'],s['stateID'],s['isEmpty']])
          end
        end
    
        # Coleta os nomes das ruas na área
        json['streets']['objects'].each do |s|
          if db.exec_params('select id from streets where id = $1',[s['id']]).ntuples == 0
            db.exec_prepared('insere_rua', [s['id'],s['name'],s['cityID'],s['isEmpty']])
          end
        end
        db.exec('vacuum')

        # Coleta os dados sobre os segmentos na area
        count = 0
        json['segments']['objects'].each do |s|
          seg = db.exec_params('select extract(epoch from last_edit_on) as updatedon from segments where id = $1',[s['id']])
          # Se o segmento é novo ou sua data de alteração é diferente da anterior então insere/altera o banco
          if seg.ntuples == 0 or (s.has_key?('updatedOn') and not s['updatedOn'].nil? and seg[0]['updatedon'].to_i != (s['updatedOn']/1000).to_i)
            db.exec_params('delete from segments where id = $1',[s['id']]) if seg.ntuples > 0
            (longitude, latitude) = s['geometry']['coordinates'][(s['geometry']['coordinates'].size / 2)]
            db.exec_prepared('insere_segmento',[s['id'], longitude, latitude, s['roadType'], s['level'], s['lockRank'], (s['updatedOn'].nil? ? s['createdBy'] : s['updatedBy']), (s['updatedOn'].nil? ? Time.at(s['createdOn']/1000) : Time.at(s['updatedOn']/1000)), s['primaryStreetID'],s['length'],((s['fwdDirection'] and s['toConnections'].size > 0) or (s['revDirection'] and s['fromConnections'].size > 0)),s['fwdDirection'],s['revDirection'],s['fwdMaxSpeed'],s['revMaxSpeed']])
            count += 1
            if count > LimitTransactions
              puts "Vacuuming..."
              db.exec('vacuum')
              count = 0
            end
          end
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
