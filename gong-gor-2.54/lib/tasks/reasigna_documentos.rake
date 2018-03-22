# encoding: UTF-8


namespace :bugs do
  desc "Reasigna documentos huerfanos"
  task :reasigna_documentos => :environment do
    Documento.all.each do |documento|
      if documento.espacio.empty? && documento.fuente_verificacion.empty? && documento.gasto.empty? && documento.transferencia.empty?
        puts "--------> El documento con ID: " + documento.id.to_s + " (" + documento.adjunto_file_name + ") no tiene espacio ni esta asociado a otra cosa"
        objeto = documento.proyecto||documento.agente
        espacio = objeto.espacio if objeto
        if espacio
          puts "          Guardando el documento en el espacio: " + espacio.inspect
          DocumentoXEspacio.find_or_create_by_documento_id_and_espacio_id documento.id, espacio.id 
        else
          puts "          Tenemos un documento huerfano!!!!!: " + documento.inspect
        end
      end
    end
  end
end

