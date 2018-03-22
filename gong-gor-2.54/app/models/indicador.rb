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
# Indicador: indicador de la matriz

class Indicador < ActiveRecord::Base
  
  scope :indicador_proyecto, lambda {|id_proyecto| { joins: ("LEFT JOIN `resultado` ON `resultado`.`id` = `indicador`.`resultado_id` LEFT JOIN `objetivo_especifico` ON `objetivo_especifico`.`id` = `indicador`.`objetivo_especifico_id` "),
                                                  conditions: (["resultado.proyecto_id = ? OR objetivo_especifico.proyecto_id = ? ", id_proyecto, id_proyecto]) } }
  
  
  
  #untranslate_all
  belongs_to :objetivo_especifico
  belongs_to :resultado
  has_many :fuente_verificacion
  has_many :variable_indicador, :dependent => :destroy
  has_many :valor_intermedio_x_indicador, :dependent => :destroy

  # Auditado de modificaciones y comentarios
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy

  # Para relaciones entre indicadores de convenios y pacs
  belongs_to :indicador_convenio, :class_name => "Indicador", :foreign_key => "indicador_convenio_id"
  has_many :indicador_pac, :class_name => "Indicador", :foreign_key => 'indicador_convenio_id'

  validate :codigo_mayusculas
  validates_uniqueness_of :codigo, :scope => [:objetivo_especifico_id, :resultado_id]
  validates_presence_of :codigo, :message => _("Código") + " " + _("no puede estar vacío.")
  validates_presence_of :descripcion, :message => _("Descripción") + " " + _("no puede estar vacía.")

  # Esto no funciona... hay que revisar la verificacion de modificacion
  #before_save :verificar_modificacion_pac
  #before_destroy :verificar_borrado
  after_create :crear_asociacion_pacs
  after_update :modificar_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  def codigo_descripcion
    codigo + " " + descripcion 
  end

  def codigo_mayusculas
    self.codigo = self.codigo.upcase
  end

  # Metodo creado para el WS de matriz.
  # Indica el estado del indicador en cada periodo de justificacion 
  def estado_seguimiento fecha_max=nil
    resultado = []
    proyecto.periodo.each do |periodo|
      estado = valor_intermedio_x_indicador.where(["fecha <= ?",periodo.fecha_inicio]).order("fecha asc").last
      resultado.push({:seguimiento_periodo_id => periodo.id, :estado => {:fecha => estado.fecha, :valor => estado.porcentaje, :comentario => estado.comentario}}) if estado
    end
    return resultado
  end

  # Muestra el ultimo valor de estado
  def estado_actual
    return valor_intermedio_x_indicador.order("fecha desc").first
  end

  def porcentaje_actual
    return estado_actual ? estado_actual.porcentaje : 0.0 
  end

  def comentario_porcentaje_actual
    return estado_actual ? estado_actual.comentario||"" : ""
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

  def proyecto
    objeto = self.objetivo_especifico || self.resultado
    return objeto ? objeto.proyecto : nil
  end

  def crear_asociacion_pacs
    proyecto = (self.objetivo_especifico || self.resultado).proyecto
    proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        miind = self.dup
        miind.objetivo_especifico_id = p.objetivo_especifico.find_by_codigo(self.objetivo_especifico.codigo).id if self.objetivo_especifico
        miind.resultado_id = p.resultado.find_by_codigo(self.resultado.codigo).id if self.resultado
        miind.indicador_convenio_id = self.id
        miind.save if miind.objetivo_especifico || miind.resultado
      end
    end if proyecto.convenio?
  end

 private

  def verificar_modificacion_pac
    obj = self.resultado || self.objetivo_especifico
    errors[:base] << _("El indicador de una Acción no se puede modificar desde el PAC.") if obj.proyecto.convenio && obj.proyecto.convenio.convenio_accion == "resultado"
    return false unless errors.empty?
  end

  def verificar_borrado
    obj = self.resultado || self.objetivo_especifico
    if self.resultado_id
      res = obj.proyecto.convenio.resultado.find_by_codigo(self.resultado.codigo) if obj.proyecto.convenio && obj.proyecto.convenio.convenio_accion == "resultado"
      errors[:base] << _("El indicador de una Acción no se puede borrar desde el PAC.") if res && res.indicador.find_by_codigo(self.codigo)
    else
      oe = obj.proyecto.convenio.resultado.find_by_codigo(self.resultado.codigo) if obj.proyecto.convenio
      errors[:base] << _("El indicador de un Objetivo Especifico no se puede borrar desde el PAC.") if oe && oe.indicador.find_by_codigo(self.codigo)
    end
    return false unless errors.empty?
  end

  def modificar_asociacion_pacs
    proyecto = (self.objetivo_especifico || self.resultado).proyecto
    proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        indicadores = Indicador.all(:include => ["resultado", "objetivo_especifico"], :conditions => ["(resultado.proyecto_id = ? OR objetivo_especifico.proyecto_id = ?) AND indicador_convenio_id = ?", p.id, p.id, self.id])
        indicadores.each do |miind|
          oe_tmp = miind.objetivo_especifico_id
          re_tmp = miind.resultado_id
          miind.attributes = self.attributes
          miind.objetivo_especifico_id = oe_tmp 
          miind.resultado_id = re_tmp
          miind.indicador_convenio_id = self.id 
          miind.save
        end if indicadores
      end
    end if proyecto.convenio?
  end

  def eliminar_asociacion_pacs
    proyecto = (self.objetivo_especifico || self.resultado).proyecto
    proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        indicadores = Indicador.all(:include => ["resultado", "objetivo_especifico"], :conditions => ["(resultado.proyecto_id = ? OR objetivo_especifico.proyecto_id = ?) AND indicador_convenio_id = ?", p.id, p.id, self.id])
        indicadores.each do |miind|
          miind.destroy
        end
      end 
    end if proyecto.convenio? 
  end
end
