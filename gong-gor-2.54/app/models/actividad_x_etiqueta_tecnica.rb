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
class ActividadXEtiquetaTecnica < ActiveRecord::Base
  belongs_to :actividad
  belongs_to :etiqueta_tecnica

  validates_presence_of :etiqueta_tecnica_id, :message => _("Etiqueta Técnica") + " " + _("no puede estar vacío.")
  validates_presence_of :actividad_id, :message => _("Actividad") + " " + _("no puede estar vacía.")
  validates_uniqueness_of :etiqueta_tecnica_id, :scope => :actividad_id, :message => _("La etiqueta ténica ya está definida para esta actividad.")

  after_create :porcentaje_total, :crear_asociacion_pacs
  after_destroy :porcentaje_total, :eliminar_asociacion_pacs

 private

    # Comprueba que el porcentaje total para la actividad no sea mayor de 1
  def porcentaje_total
    totales= actividad.actividad_x_etiqueta_tecnica.count
    porcentaje = 1.0/totales
    actividad.actividad_x_etiqueta_tecnica.each do |axet|
      axet.update_attribute "porcentaje", porcentaje 
    end
  end

    # Si el proyecto asociado es un convenio, copia la relacion a los pacs existentes
  def crear_asociacion_pacs
    Actividad.where(:actividad_convenio_id => self.actividad_id).each do |a|
      p = a.proyecto
      if p && p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        ActividadXEtiquetaTecnica.create(:actividad_id => a.id, :etiqueta_tecnica_id => self.etiqueta_tecnica_id, :porcentaje => self.porcentaje)
      end
    end
  end

    # Si el proyecto asociado es un convenio, elimina la relacion de los pacs existentes
  def eliminar_asociacion_pacs
    Actividad.where(:actividad_convenio_id => self.actividad_id).each do |a|
      p = a.proyecto
      if p && p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        ActividadXEtiquetaTecnica.find_by_actividad_id_and_etiqueta_tecnica_id(a.id, self.etiqueta_tecnica_id).destroy
      end
    end
  end

end
