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
# resultados de la matriz

class Resultado < ActiveRecord::Base

  before_destroy :verificar_borrado

  validate :valida_formato_codigo
  validates_uniqueness_of :codigo, :scope => :proyecto_id, :message => _("El código '%{value}' ya está siendo utilizado en el proyecto por otro resultado."), :case_sensitive => false
  validates_presence_of :descripcion, :message => _("Descripción") + " " + _("no puede estar vacía.")

  belongs_to :proyecto
  belongs_to :objetivo_especifico
  has_many :actividad, :order => "actividad.codigo"
  has_many :hipotesis, :dependent => :destroy
  has_many :indicador, :order => "codigo", :dependent => :destroy
  has_many :fuente_verificacion, :order => "codigo", :dependent => :destroy
  has_many :comentario, as: :elemento, dependent: :destroy

  #before_save :verificar_modificacion_pac
  after_create :crear_asociacion_pacs
  after_update :modificar_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  def valida_formato_codigo
    # Comprueba que no contenga @ (referencia a OE en importacion) o # (referencia a Resultado en importacion)
    if self.codigo.match(/[@#]/)
      errors.add _("Código"), _("El código no puede contener los caracteres '@' ó '#'.")
    else
      # Elimina los espacios anteriores y posteriores, cambia el resto por "_" y lo pone todo en mayusculas
      self.codigo = self.codigo.upcase.gsub(' ','_')
    end
    return errors.empty?
  end

  # Devuelve codigo y nombre
  def codigo_nombre
    self.codigo + " " +self.descripcion
  end

  def crear_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        mires = self.dup
        mires.proyecto_id = p.id
        mires.objetivo_especifico_id = p.objetivo_especifico.find_by_codigo(self.objetivo_especifico.codigo).id
        mires.save
      end
    end if self.proyecto.convenio?
  end

  def suma_presupuesto
    0.0 if actividad.empty?
    Presupuesto.sum "presupuesto_x_actividad.importe * tasa_cambio",  :include => ["presupuesto_x_actividad", "tasa_cambio"], :conditions => { "presupuesto_x_actividad.actividad_id" => actividad.collect{|a| a.id}, "presupuesto.proyecto_id" => proyecto_id } unless actividad.empty?
  end

 private

  def verificar_modificacion_pac
    errors[:base] << _("Una acción no se puede modificar desde el PAC.") if self.proyecto.convenio && self.proyecto.convenio.convenio_accion == "resultado"
    return false unless errors.empty?
  end

  def verificar_borrado
    numero_errores = 0
    Actividad.where(:resultado_id => id).each do |a|
      a.destroy
      numero_errores = (numero_errores + 1) unless a.errors.empty?
    end
    errors[:base] << _("Existen %{num} actividades vinculadas con presupuestos o gastos asignados.")%{:num => numero_errores} unless numero_errores == 0
    return false unless errors.empty?
  end

  def modificar_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        mires = p.resultado.find_or_create_by_codigo(self.codigo_was)
        if mires
          mires.attributes = self.attributes
          mires.proyecto_id = p.id
          mires.objetivo_especifico_id = p.objetivo_especifico.find_by_codigo(self.objetivo_especifico.codigo).id
          mires.save
        end
      end
    end if self.proyecto.convenio?
  end

  def eliminar_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Permite borrar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        miobj = p.objetivo_especifico.find_by_codigo(self.objetivo_especifico.codigo)
        Resultado.destroy_all(:proyecto_id => p.id, :objetivo_especifico_id => miobj.id, :codigo => self.codigo) if miobj
      end
    end if self.proyecto.convenio?
  end
end
