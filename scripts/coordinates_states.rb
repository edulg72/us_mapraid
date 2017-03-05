require 'pg'

if ARGV.size > 0
  passo = ARGV[0].to_f
else
  passo = 0.09
end

if ARGV.size > 1
  sigla = "and sigla = '#{ARGV[1]}' "
else
  sigla = nil
end

puts "#!/bin/bash\n\necho \"Start: $(date '+%d/%m/%Y %H:%M:%S')\"\n\ncase \"$3\" in"

db = PG::Connection.new(:hostaddr => '127.0.0.1', :dbname => 'us_mapraid', :user => 'waze', :password => 'waze')
db.prepare('box_estado','select name from cities_mapraid where (ST_Overlaps(geom,ST_SetSRID(ST_MakeBox2D(ST_Point($1,$2),ST_Point($3,$4)),4326)) or ST_Contains(geom,ST_SetSRID(ST_MakeBox2D(ST_Point($1,$2),ST_Point($3,$4)),4326)))')

db.exec("select ST_Xmin(ST_Envelope(geom)) as longoeste, ST_Xmax(ST_Envelope(geom)), ST_Ymax(ST_Envelope(geom)) as latnorte, ST_Ymin(ST_Envelope(geom)) as latsul from (select ST_Union(geom) as geom from cities_mapraid) as cities").each do |estado|
  puts "  #{estado['name']})"
  latIni = (estado['latnorte'].to_f.round(2) + 0.01).round(8)
  while latIni > estado['latsul'].to_f
#    puts "Latitude: [#{latIni} #{(latIni - passo).round(8)}]"
    area = false
    out = ''
    lonIni = (estado['longoeste'].to_f.round(2) - 0.01).round(8)
    while lonIni < estado['longleste'].to_f
#      puts "  Longitude: [#{lonIni} #{(lonIni + passo).round(8)}] #{area}"
      if area
        if db.exec_prepared('box_estado',[lonIni, (latIni - passo).round(8), (lonIni + passo).round(8), latIni]).ntuples == 0
          area = false
          puts "#{out} #{lonIni} #{(latIni - passo).round(8)} #{passo}"
          out = ''
        end
      else
        if db.exec_prepared('box_estado',[lonIni, (latIni - passo).round(8), (lonIni + passo).round(8), latIni]).ntuples > 0
          area = true
          out = "    ruby busca_segments.rb $1 $2 #{lonIni} #{latIni}"
        end
      end
      lonIni = (lonIni + passo).round(8)
    end
    latIni = (latIni - passo).round(8)
  end
  puts "  ;;"
end
puts "  *)\n    echo \"Usage: script_name.sh <user> <password> <state code>\"\n    exit 1\nesac\n"
