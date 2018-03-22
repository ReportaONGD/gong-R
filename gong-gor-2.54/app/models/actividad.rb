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
# actividad de la matriz

# Gestiona el modelo actividad.
class Actividad < ActiveRecord::Base

  before_destroy :verificar_borrado

  validate :valida_formato_codigo
  validates_uniqueness_of :codigo, :scope => :proyecto_id, :message => _("El código '%{value}' ya está siendo utilizando en el proyecto por otra actividad."), :case_sensitive => false
  validates_presence_of :codigo, :message => _("Código") + " " + _("no puede estar vacío.")
  validates_presence_of :descripcion, :message => _("Descripción") + " " + _("no puede estar vacío.")
  belongs_to :proyecto
  belongs_to :resultado
  has_many :gasto_x_actividad, :dependent => :destroy
  has_many :presupuesto_x_actividad, :dependent => :destroy
  has_many :presupuesto, :through => :presupuesto_x_actividad
  has_many :contrato_x_actividad, :dependent => :destroy
  has_many :contrato, :through => :contrato_x_actividad
  has_many :actividad_x_pais, :dependent => :destroy
  has_many :pais, :through => :actividad_x_pais
  has_many :actividad_x_etiqueta_tecnica, :dependent => :destroy
  has_many :etiqueta_tecnica, :through => :actividad_x_etiqueta_tecnica
  has_many :actividad_x_etapa, :dependent => :destroy
  has_many :etapa, :through => :actividad_x_etapa
  has_many :actividad_detallada, :dependent => :destroy
  has_many :subactividad, :order => "descripcion", :dependent => :destroy

  # Auditado de modificaciones y comentarios
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy
  
  # Para relaciones entre actividades de convenios y pacs
  belongs_to :actividad_convenio, :class_name => "Actividad", :foreign_key => "actividad_convenio_id"
  has_many :actividad_pac, :class_name => "Actividad", :foreign_key => 'actividad_convenio_id'

  after_create :asigna_etapa_unica, :crear_asociacion_pacs
  after_update :borrar_actividad_detallada, :modificar_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  # Antes de guardar convertimos la fecha de fin para que sea el ultimo dia
  #before_save  "self.fecha_fin = (self.fecha_fin >> 1) - 1"

  # Devuelve codigo y nombre
  def codigo_nombre
    self.codigo + " " +self.descripcion
  end
  def codigo_descripcion
    self.codigo + " - " +self.descripcion
  end

  def valida_formato_codigo
    # Comprueba que no contenga @ (referencia a OE en importacion) o # (referencia a Resultado en importacion)
    if self.codigo.match(/[@#]/)
      errors.add _("Código"), _("El código no puede contener los caracteres '@' ó '#'.")
    else
      # Elimina los espacios anteriores y posteriores,
      # cambia el resto de espacios por "_" y lo pone todo en mayusculas
      self.codigo = self.codigo.upcase.gsub(' ','_')
    end
    return errors.empty?
  end

  def suma_presupuesto
    Presupuesto.sum "presupuesto_x_actividad.importe * tasa_cambio",  :include => ["presupuesto_x_actividad", "tasa_cambio"], :conditions => { "presupuesto_x_actividad.actividad_id" => id, "presupuesto.proyecto_id" => proyecto_id }
    #Presupuesto.joins(:presupuesto_x_actividad, :tasa_cambio).where({ "presupuesto_x_actividad.actividad_id" => id, "presupuesto.proyecto_id" => proyecto_id }).sum  "presupuesto_x_actividad.importe * tasa_cambio"
  end

  def presupuesto_x_partida_financiador
    campos = "sum(importe_moneda_base) as suma_importe, partida_proyecto_nombre, partida_proyecto_id"
    condiciones = { proyecto_id: self.proyecto_id, actividad_id: self.id }
    agrupacion = "partida_proyecto_id"
    VPresupuesto.find :all, conditions: condiciones, group: agrupacion, select: campos
  end

  def numero_presupuesto 
    Presupuesto.count  :include => ["presupuesto_x_actividad", "tasa_cambio"], :conditions => { "presupuesto_x_actividad.actividad_id" => id, "presupuesto.proyecto_id" => proyecto_id }
    #Presupuesto.joins(:presupuesto_x_actividad, :tasa_cambio).where({ "presupuesto_x_actividad.actividad_id" => id, "presupuesto.proyecto_id" => proyecto_id }).count
  end

 def porcentaje_presupuesto 
    #total = Presupuesto.sum "presupuesto_x_actividad.importe * tasa_cambio", :include => ["presupuesto_x_actividad","tasa_cambio"], :conditions => {"presupuesto.proyecto_id" => proyecto_id }
    total = Presupuesto.joins(:presupuesto_x_actividad, :tasa_cambio).where({"presupuesto.proyecto_id" => proyecto_id }).sum "presupuesto_x_actividad.importe * tasa_cambio"
    (suma_presupuesto.to_f / total.to_f) * 100
 end


  # Si al crear sólo existe una etapa, le asignamos esta si no está seleccionada
  def asigna_etapa_unica
    if self.proyecto.etapa.count == 1
      ActividadXEtapa.create(:actividad_id => self.id, :etapa_id => self.proyecto.etapa.first.id)
    end
  end

  def crear_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        miact = self.dup
        mires = self.resultado ? p.resultado.find_by_codigo(self.resultado.codigo) : nil
        miact.resultado_id = mires.id if mires
        miact.proyecto_id = p.id
        miact.actividad_convenio_id = self.id
        miact.save
        miact.pais_ids = self.pais.collect{|p| p.id} if miact.errors.empty?
        miact.etiqueta_tecnica_ids = self.etiqueta_tecnica.collect{|et| et.id} if miact.errors.empty?
      end
    end if self.proyecto.convenio?
  end

  def estado_actual etap=nil
    # cual seria independientemente de la etapa? (Ticket #1811)
    etap ||= (etapa.count == 1 ? etapa.first : nil)
    axe = actividad_x_etapa.find_by_etapa_id(etap.id) if etap
    return axe.estado_actual if axe
  end

  # Metodo creado para el WS de cronograma
  def actividad_detallada_prevision
    actividad_detallada.where seguimiento: false
  end

  # Metodo creado para el WS de cronograma
  def actividad_detallada_seguimiento
    actividad_detallada.where seguimiento: true
  end

  # Metodo creado para el WS de matriz.
  # Indica el estado de la actividad en cada etapa.
  def estado_actividad fecha=nil
    estado = ValorIntermedioXActividad.includes(:actividad_x_etapa).where("actividad_x_etapa.actividad_id" => self.id)
    estado = estado.where(["fecha < ?",fecha]) if fecha
    return estado.order("fecha asc")
  end

  # Metodo creado para el WS de matriz.
  # Indica el estado de la actividad en cada periodo de justificacion 
  def estado_seguimiento fecha_max=nil
    resultado = []

    # Para los PACs y convenios, busca agrupado por etapas
    if (proyecto.convenio_id || proyecto.convenio?)
      cond_etap = fecha_max ? ["fecha_fin <= ?", fecha_max] : nil
      proyecto.etapa.where(cond_etap).each do |periodo|
        estado = self.estado_actividad(periodo.fecha_fin + 1.day).last
        resultado.push({:nombre => periodo.nombre, :estado => {:fecha => estado.fecha, :porcentaje => estado.porcentaje, :realizada => estado.realizada, :comentario => estado.comentario}}) if estado
      end
    # Para los proyectos, muestra segun los periodos de justificacion
    else
      proyecto.periodo_justificacion.each do |periodo|
        estado = self.estado_actividad(periodo.fecha_inicio).last
        resultado.push({:seguimiento_periodo_id => periodo.id, :estado => {:fecha => estado.fecha, :porcentaje => estado.porcentaje, :realizada => estado.realizada, :comentario => estado.comentario}}) if estado
      end
    end

    return resultado
  end

 private

  # Si alguno de as 
  def borrar_actividad_detallada
    actividad_detallada.each do |ad|
      ad.destroy unless etapa_ids.include?(ad.etapa_id)
    end
  end

  def verificar_borrado
    errors.add( "presupuesto", _("hay presupuestos")) unless self.presupuesto_x_actividad.empty?
    errors.add( "gasto", _("hay gastos")) unless self.gasto_x_actividad.empty?
    errors.add( "contrato", _("hay contratos asociados")) unless self.contrato_x_actividad.empty?
    errors[:base] << ( _("Una actividad tiene que estar vacia para poder ser borrado.") ) unless errors.empty?
    return errors.empty?
  end

  def modificar_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Permite modificar solo si el pac esta en formulacion
      if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
        #puts "Modificando la actividad " + self.codigo + " para el proyecto " + p.id.to_s
        #miact = p.actividad.find_by_codigo(self.codigo_was)
        #puts "--------------> No tenemos la actividad!!!" unless miact
        #if miact
        actividades = p.actividad.all(:conditions => {:actividad_convenio_id => self.id})
        actividades.each do |miact| 
          miact.attributes = self.attributes
          miact.proyecto_id = p.id
          mires = self.resultado ? p.resultado.find_by_codigo(self.resultado.codigo) : nil
          miact.resultado_id = mires.id if mires
          miact.actividad_convenio_id = self.id
          miact.save
          miact.pais_ids = self.pais.collect{|p| p.id} if miact.errors.empty?
          miact.etiqueta_tecnica_ids = self.etiqueta_tecnica.collect{|et| et.id} if miact.errors.empty?
        end if actividades
      end
    end if self.proyecto && self.proyecto.convenio?
  end

  def eliminar_asociacion_pacs
    self.proyecto.pacs.each do |p|
      Actividad.destroy_all(:proyecto_id => p.id, :codigo => self.codigo) if p.estado_actual.nil? || p.estado_actual.definicion_estado.formulacion
    end if self.proyecto && self.proyecto.convenio?
  end
end
