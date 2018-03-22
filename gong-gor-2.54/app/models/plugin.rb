# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Free Software's Seed
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
# ActiveResource que gestiona plugins 

class Plugin < ActiveRecord::Base

  scope :activos, -> { where(activo: true).order(:peso) }
  scope :engines_activos, -> { where(activo: true, engine: true) }

  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  validates_uniqueness_of :codigo, :message => _("Código repetido.")
  validates_uniqueness_of :clase, :message => _("Clase repetida.")

  # Mantenimiento de plugins instalados y disponibles.
  def self.comprueba_plugins
    base_path = ENV['GOR_PLUGINS'] + "/"
    # Mira los plugins disponibles en el directorio de plugins
    posibles = Dir.glob(base_path + '*').select {|f| File.directory? f}
    logger.info("#{Dir.glob(base_path + '*')}")
    # Primero verifica que los ya cargados sigan existiendo
    Plugin.all.each do |plugin|
      logger.info "base_path->#{base_path} plugin.codigo->#{plugin.codigo} #{posibles.include?(base_path + plugin.codigo)}"
      if posibles.include?(base_path + plugin.codigo)
        posibles.delete(base_path + plugin.codigo)
        logger.info "--------> (GOR) El plugin '#{plugin.clase}' vuelve a estar disponible..." unless plugin.disponible
        plugin.actualiza_info_plugin
      else
        logger.info "--------> (GOR) El plugin '#{plugin.clase}' ya no esta disponible. Desactivando..."
        plugin.update_attributes(disponible: false, activo: false)
      end
    end
    # Y luego incluye los que no lo estuvieran ya
    posibles.each do |p|
      codigo = p.split('/').last
      logger.info "--------> (GOR) Registrando el plugin '#{codigo.camelize}'..."
      begin
        clase = eval(codigo.camelize)
        plugin=Plugin.create(codigo: codigo, clase: codigo.camelize, nombre: clase::SUMMARY)
        plugin.actualiza_info_plugin
      rescue Exception => e
        logger.error "--------> (GOR) Exception analyzing plugin '" + codigo.camelize + "': " + e.inspect
      end
    end
  end

  # Devuelve los plugins disponibles y activados despues de comprobarlos
  def self.rutas_activas
    # Solo funcionamos la tabla existe. Esto es asi porque la migracion carga el routes
    # y el routes invoca este metodo, con lo que casca a la hora de migrar (generarse la tabla)
    if ActiveRecord::Base.connection.table_exists? 'plugin'
      Plugin.comprueba_plugins
      Plugin.engines_activos 
    else
      []
    end 
  end

  # Actualiza las rutas de la aplicacion
  def self.recarga_rutas
    logger.info "--------> (GOR) Recargando rutas por cambio en plugins"
    Rails.application.reload_routes! 
  end

  # Actualiza los plugins de autenticacion disponibles
  def self.search_external_auth
    # Definimos la variable inicial para recoger modulos de autentificaciones externas
    Gor::Application.config.external_auth = []
    # Y le metemos los plugins que tiene declarado endpoint externo
    Plugin.engines_activos.each do |plugin|
      begin
        Gor::Application.config.external_auth.push(eval(plugin.clase).endpoints) if eval(plugin.clase).respond_to?(:endpoints)
      rescue Exception => e
        logger.error "--------> (GOR) Exception looking for external auth plugins: " + e.inspect
      end
    end
  end

  # Actualiza la info de un plugin
  def actualiza_info_plugin
    klass = eval(self.clase)
    self.update_attributes(version: klass::VERSION, descripcion: klass::DESCRIPTION)
    self.update_attributes(engine: klass::ENGINE) if klass.const_defined?("ENGINE")
    self.update_attributes(peso: klass::WEIGHT) if klass.const_defined?("WEIGHT")
    self.update_attributes(disponible: true) unless self.disponible
  end
end

