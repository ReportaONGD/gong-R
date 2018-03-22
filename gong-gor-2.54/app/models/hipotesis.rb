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
# hipotesis

class Hipotesis < ActiveRecord::Base
  #untranslate_all
  belongs_to :objetivo_especifico
  belongs_to :resultado

  after_create :crear_asociacion_pacs
  after_update :modificar_asociacion_pacs
  after_destroy :modificar_asociacion_pacs

  def crear_asociacion_pacs
    proyecto = (self.objetivo_especifico || self.resultado).proyecto
    proyecto.pacs.each do |p|
      self.clonar_hipotesis(p) if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
    end if proyecto.convenio? && (self.objetivo_especifico || proyecto.convenio_accion == 'resultado')
  end

  def clonar_hipotesis proyecto
    mihip = Hipotesis.new(:descripcion => self.descripcion)
    coletilla = " " + _("en el PAC") + " " + proyecto.nombre
    if self.objetivo_especifico
      mioe = proyecto.objetivo_especifico.find_by_codigo(self.objetivo_especifico.codigo)
      mihip.objetivo_especifico_id = mioe.id if mioe
      errors.add( "objetivo_especifico", _("no existe el objetivo especifico asociado a la hipotesis") + coletilla) if mioe.nil?
    else
      mires = proyecto.resultado.find_by_codigo(self.resultado.codigo)
      mihip.resultado_id = mires.id if mires
      errors.add( "resultado", _("no existe el resultado asociado a la hipotesis") + coletilla) if mires.nil? && self.resultado.proyecto.convenio_accion == "resultado"
    end
    mihip.save if mihip.resultado || mihip.objetivo_especifico
  end

 private

  def modificar_asociacion_pacs
    proyecto = (self.objetivo_especifico || self.resultado).proyecto
    proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        obj = p.objetivo_especifico.find_by_codigo(self.objetivo_especifico.codigo) if self.objetivo_especifico
        obj = p.resultado.find_by_codigo(self.resultado.codigo) if self.resultado
        # Destruye todas las hipotesis del pac del resultado o el objetivo especifico
        obj.hipotesis.destroy_all if obj 
        # Y las vuelve a crear
        (self.objetivo_especifico || self.resultado).hipotesis.each { |hip| clonar_hipotesis p } if obj 
      end
    end if proyecto.convenio? && (self.objetivo_especifico || proyecto.convenio_accion == 'resultado')
  end

end
