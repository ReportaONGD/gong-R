# encoding: UTF-8


namespace :bugs do
  desc "Reasigna partidas de financiacion madre mal vinculadas en los pacs"
  task :reasigna_partidas_madre_pacs => :environment do
    PartidaFinanciacion.all(:conditions => ["padre=0 AND agente_id IS NULL AND partida_financiacion_id IS NOT NULL"]).each do |pf|
      proyecto = pf.proyecto
      if proyecto && proyecto.convenio_id && pf.partida_financiacion_id
        pf_madre = pf.partida_financiacion_madre
        if pf_madre
          pf_nueva_madre = PartidaFinanciacion.where(:proyecto_id => pf.proyecto_id, :codigo => pf_madre.codigo).first
          if pf_nueva_madre
            if pf.partida_financiacion_id != pf_nueva_madre.id
              pf.partida_financiacion_id = pf_nueva_madre.id 
              puts "-----------> Cambiando la PF madre de " + pf.id.to_s + " desde " + pf_madre.id.to_s + " hacia " + pf_nueva_madre.id.to_s
              pf.save
            end
          else
            puts "-----------> REVISAME: No se encontro la madre la PF " + pf.id.to_s + " en el proyecto " + pf.proyecto_id.to_s
            puts "                       " + pf.inspect
          end
        else
          puts "-----------> REVISAME: No se encontro la madre de la PF " + pf.id.to_s
          puts "                       " + pf.inspect
        end
      end
    end
  end
end


