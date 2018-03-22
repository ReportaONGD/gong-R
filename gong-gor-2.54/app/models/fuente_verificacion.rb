# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed, CENATIC y IEPALA
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
# fuente de verificación

class FuenteVerificacion < ActiveRecord::Base
  
  scope :fuente_verificacion_proyecto, lambda {|id_proyecto| { joins: ("LEFT JOIN `resultado` ON `resultado`.`id` = `fuente_verificacion`.`resultado_id` LEFT JOIN `objetivo_especifico` ON `objetivo_especifico`.`id` = `fuente_verificacion`.`objetivo_especifico_id` "),
                                                               conditions: (["resultado.proyecto_id = ? OR objetivo_especifico.proyecto_id = ? ", id_proyecto, id_proyecto]) } }
  
  
  #untranslate_all
  belongs_to :indicador
  belongs_to :objetivo_especifico
  belongs_to :resultado

  has_many :fuente_verificacion_x_documento
  has_many :documento, :through => :fuente_verificacion_x_documento

  # Auditado de modificaciones y comentarios
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy

  # Para relaciones entre fv de convenios y pacs
  belongs_to :fuente_verificacion_convenio, :class_name => "FuenteVerificacion", :foreign_key => "fuente_verificacion_convenio_id"
  has_many :fuente_verificacion_pac, :class_name => "FuenteVerificacion", :foreign_key => 'fuente_verificacion_convenio_id'

  validate :codigo_mayusculas
  validates_presence_of :codigo, :message => _("Código") + " " + _("no puede estar vacío.")
  validates_presence_of :descripcion, :message => _("Descripción") + " " + _("no puede estar vacía.")
  validates_uniqueness_of :codigo, :scope => [:objetivo_especifico_id, :resultado_id], :message => _("Código repetido.")

  after_create :crear_asociacion_pacs
  after_update :modificar_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  def codigo_mayusculas
    self.codigo = self.codigo.upcase
  end

  def codigo_completo
    completo=codigo
    if self.resultado
      completo += " (" + self.resultado.objetivo_especifico.codigo + " / " + self.resultado.codigo + ")"
    else
      completo += " (" + self.objetivo_especifico.codigo + ")"
    end
    return completo
  end

  def objetivo_resultado
    if !(objetivo_especifico.nil?); "(Objetivo) " + objetivo_especifico.codigo_nombre;
    elsif !(resultado.nil?); "(Resultado) " + resultado.codigo_nombre;
    else "";
    end
  end

  def proyecto
    (self.objetivo_especifico || self.resultado).proyecto
  end

  def crear_asociacion_pacs
    proyecto = (self.objetivo_especifico || self.resultado).proyecto
    proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        obj = p.objetivo_especifico.find_by_codigo(self.objetivo_especifico.codigo) if self.objetivo_especifico
        obj = p.resultado.find_by_codigo(self.resultado.codigo) if self.resultado
        ind = obj.indicador.find_by_codigo( self.indicador.codigo ) if self.indicador
        mifv = self.dup
        mifv.objetivo_especifico_id = obj.id if self.objetivo_especifico
        mifv.resultado_id = obj.id if self.resultado
        mifv.indicador_id = ind.id if self.indicador && ind
        mifv.fuente_verificacion_convenio_id = self.id
        mifv.save
      end
    end if proyecto.convenio?
  end

 private

  def modificar_asociacion_pacs
    proyecto = (self.objetivo_especifico || self.resultado).proyecto
    proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        fuentes = FuenteVerificacion.all(:include => ["resultado", "objetivo_especifico"], :conditions => ["(resultado.proyecto_id = ? OR objetivo_especifico.proyecto_id = ?) AND fuente_verificacion_convenio_id = ?", p.id, p.id, self.id])
        fuentes.each do |mifv|
          oe_tmp = mifv.objetivo_especifico_id
          re_tmp = mifv.resultado_id
          in_tmp = mifv.indicador_id
          mifv.attributes = self.attributes
          mifv.objetivo_especifico_id = oe_tmp 
          mifv.resultado_id = re_tmp 
          mifv.indicador_id = in_tmp
          mifv.fuente_verificacion_convenio_id = self.id
          mifv.save
        end if fuentes
      end
    end if proyecto.convenio?
  end

  def eliminar_asociacion_pacs
    proyecto = (self.objetivo_especifico || self.resultado).proyecto
    proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        fuentes = FuenteVerificacion.all(:include => ["resultado", "objetivo_especifico"], :conditions => ["(resultado.proyecto_id = ? OR objetivo_especifico.proyecto_id = ?) AND fuente_verificacion_convenio_id = ?", p.id, p.id, self.id])
        fuentes.each do |mifv|
          mifv.destroy
        end
      end
    end if proyecto.convenio?
  end
end
