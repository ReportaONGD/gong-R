# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2013 Free Software's Seed, CENATIC y IEPALA
#
# Licencia con arreglo a la EUPL, Versión 1.1 o –en cuanto sean aprobadas por la Comisión Europea– 
# versiones posteriores de la EUPL (la «Licencia»);
# Solo podrá usarse esta obra si se respeta la Licencia.
# Puede obtenerse una copia de la Licencia en:
#
# http://www.osor.eu/eupl/european-union-public-licence-eupl-v.1.1
#
# Salvo cuando lo exija la legislación aplicable o se acuerde por escrito, 
# el programa distribuido con arreglo a la Licencia se distribuye «TAL CUAL»,
# SIN GARANTÍAS NI CONDICIONES DE NINGÚN TIPO, ni expresas ni implícitas.
# Véase la Licencia en el idioma concreto que rige los permisos y limitaciones que establece la Licencia.
#################################################################################
#
#++
# Controlador encargado de backups de BBDD

class BackupController < ApplicationController
  def index
  end

  def seleccionar
    fichero_backup = "#{ENV['TMPDIR']}/backup"

    if params[:selector] && params[:selector][:tipo] == "bbdd"
      database_config_file = ENV['GOR_SITEID'] ? ENV['RAILS_ETC'] + '.database.yml' : 'config/database.yml'
      db_config = Gor::Application.config.database_configuration[::Rails.env]

      fichero_backup = "#{ENV['TMPDIR']}/backup.gz"
      nombre_fichero = (ENV['GOR_SITEID']? ENV['GOR_SITEID'] : "gor") + "_backup_bbdd_" + Time.new.strftime("%Y%m%d") + ".sql.gz"

      system "mysqldump -u #{db_config['username']} --routines -p#{db_config['password']} #{db_config['database']} | gzip -c > #{fichero_backup}"

    elsif params[:selector] && params[:selector][:tipo] == "docus"
      documents_path = ENV['RAILS_VAR']
      nombre_fichero = (ENV['GOR_SITEID']? ENV['GOR_SITEID'] : "gor") + "_backup_documentos_" + Time.new.strftime("%Y%m%d") + ".tar.gz"
     
      system "tar chzf " + fichero_backup + " " + ENV['RAILS_VAR']

    else
      msg _("Seleccione un tipo de backup.")
      redirect_to :action => 'index' 
    end

    if File.exists?(fichero_backup)
      send_file fichero_backup,
        :disposition => 'attachment',
        :type => 'application/gzip',
        :encoding => 'utf8',
        :filename => nombre_fichero
      # Elimina los ficheros temporales para no dejarlo sucio (no se puede borrar aqui)
      #File.delete (fichero_salida)
    else
      msg_error _("Error al realizar el backup. Contacte con el administrador del sistema.")
      redirect_to :action => 'index'
    end
  end
end
