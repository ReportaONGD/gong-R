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
class PartidaFinanciacion < ActiveRecord::Base

  belongs_to :proyecto
  belongs_to :agente
  has_many :partida, :through => :partida_x_partida_financiacion, :uniq => true
  has_many :partida_x_partida_financiacion, :dependent => :destroy

  # Para partidas madres/hijas
  belongs_to :partida_financiacion_madre, :class_name => "PartidaFinanciacion", :foreign_key => "partida_financiacion_id"
  has_many :partida_financiacion_hija, :class_name => "PartidaFinanciacion", :foreign_key => 'partida_financiacion_id', :order => "codigo", :dependent => :nullify

  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :codigo, :message => _("Código") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :nombre, :scope => [:proyecto_id,:agente_id], :message => _("Nombre repetido.")
  validates_uniqueness_of :codigo, :scope => [:proyecto_id,:agente_id], :message => _("Código repetido.")

  before_validation :comprobar_partida_financiacion_padre, :on => :update

  after_create :crear_asociacion_pacs
  after_update :modificar_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  def subpartida_proyecto proyecto_id
    subpartidas = Array.new
    for part in partida
      Subpartida.find_all_by_proyecto_id_and_partida_id(proyecto_id, part.id).each {|sub|  subpartidas.push( sub ) }
    end
    return (subpartidas.sort{|x,y| x.nombre <=> y.nombre}).uniq
  end

  def codigo_nombre 
    return self.codigo + "  " + self.nombre 
  end

  def tipo_mayusculas
    self.tipo.capitalize if self.tipo
  end

	# Ajusta valores si la partida es padre
  def comprobar_partida_financiacion_padre
    # No tiene partida madre si la partida ya es madre
    self.partida_financiacion_id = nil if self.padre
    # Ajusta el tipo de partida segun el padre
    self.tipo = partida_financiacion_madre.tipo if partida_financiacion_madre
    # Muestra errores si la partida padre es ella misma
    errors.add( "partida_financiacion_id", _("La partida superior no puede ser la misma partida"))  if partida_financiacion_id == id
    return false unless errors.empty?
  end


        # Devuelve el total de importe (en moneda base) de los presupuestos asignados a esta partida
  def suma_presupuesto
    if padre
      suma = 0
      partida_financiacion_hija.each do |pxf|
        suma += Presupuesto.sum( "importe * tasa_cambio",  :include => ["partida_x_partida_financiacion", "tasa_cambio"], :conditions => { "partida_x_partida_financiacion.partida_financiacion_id" => pxf.id, "presupuesto.proyecto_id" => proyecto_id }).to_f
      end
    else
      suma = Presupuesto.sum "importe * tasa_cambio",  :include => ["partida_x_partida_financiacion", "tasa_cambio"], :conditions => { "partida_x_partida_financiacion.partida_financiacion_id" => id, "presupuesto.proyecto_id" => proyecto_id }
    end
    return suma
  end

        # Devuelve el total de importe (en moneda base) de los presupuestos asignados a esta partida y el financiador indicado
  def suma_presupuesto_financiador financiador_id
    if padre
      suma = 0
      partida_financiacion_hija.each do |pxf|
        suma += Presupuesto.sum( "presupuesto_x_agente.importe * tasa_cambio",  :include => ["partida_x_partida_financiacion", "tasa_cambio", "presupuesto_x_agente"], :conditions => { "partida_x_partida_financiacion.partida_financiacion_id" => pxf.id, "presupuesto.proyecto_id" => proyecto_id, "presupuesto_x_agente.agente_id" => financiador_id }).to_f
      end
    else
      suma = Presupuesto.sum "presupuesto_x_agente.importe * tasa_cambio",  :include => ["partida_x_partida_financiacion", "tasa_cambio", "presupuesto_x_agente"], :conditions => { "partida_x_partida_financiacion.partida_financiacion_id" => id, "presupuesto.proyecto_id" => proyecto_id, "presupuesto_x_agente.agente_id" => financiador_id }
    end
    return suma
  end

        # Devuelve el numero total de presupuestos vinculados al presupuesto
  def numero_presupuesto
    if padre
      suma = 0
      partida_financiacion_hija.each do |pxf|
        suma += Presupuesto.count( :include => ["partida_x_partida_financiacion", "tasa_cambio"], :conditions => { "partida_x_partida_financiacion.partida_financiacion_id" => pxf.id, "presupuesto.proyecto_id" => proyecto_id })
      end
    else
      suma = Presupuesto.count  :include => ["partida_x_partida_financiacion", "tasa_cambio"], :conditions => { "partida_x_partida_financiacion.partida_financiacion_id" => id, "presupuesto.proyecto_id" => proyecto_id }
    end
    return suma
  end

	# Devuelve el porcentaje presupuestado para esta partida frente al total
 def porcentaje_presupuesto 
    #total = Presupuesto.sum "importe * tasa_cambio", :include => ["tasa_cambio"], :conditions => {"presupuesto.proyecto_id" => proyecto_id }
    total = Presupuesto.joins(:tasa_cambio).where({"presupuesto.proyecto_id" => proyecto_id }).sum "importe * tasa_cambio.tasa_cambio"
    (suma_presupuesto.to_f / total.to_f) * 100
 end

	# Devuelve el porcentaje presupuestado para esta partida y financiador frente al total
 def porcentaje_presupuesto_financiador financiador_id
    total = Presupuesto.sum "presupuesto_x_agente.importe * tasa_cambio", :include => ["tasa_cambio", "presupuesto_x_agente"], :conditions => {"presupuesto.proyecto_id" => proyecto_id, "presupuesto_x_agente.agente_id" => financiador_id  }
    (suma_presupuesto_financiador(financiador_id).to_f / total.to_f) * 100
 end


 private
  def crear_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Solo actua si la pac no esta cerrada
      if p.estado_actual.nil? || !p.estado_actual.definicion_estado.cerrado
        mipf_madre = self.partida_financiacion_madre ? p.partida_financiacion.find_or_create_by_codigo(self.partida_financiacion_madre.codigo) : nil
        mipf = self.dup
        mipf.proyecto_id = p.id
        mipf.partida_financiacion_id = mipf_madre ? mipf_madre.id : nil 
        mipf.save
      end
    end if self.proyecto && self.proyecto.convenio?
  end

  def modificar_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Solo actua si la pac no esta cerrada
      if p.estado_actual.nil? || !p.estado_actual.definicion_estado.cerrado
        mipf = p.partida_financiacion.find_or_create_by_codigo(self.codigo_was)
        mipf_madre = self.partida_financiacion_madre ? p.partida_financiacion.find_or_create_by_codigo(self.partida_financiacion_madre.codigo) : nil
        mipf.attributes = self.attributes
        mipf.proyecto_id = p.id
        mipf.partida_financiacion_id = mipf_madre ? mipf_madre.id : nil
        mipf.save
      end
    end if self.proyecto && self.proyecto.convenio?
  end

  def eliminar_asociacion_pacs
    self.proyecto.pacs.each do |p|
      # Solo actua si la pac no esta cerrada
      PartidaFinanciacion.destroy_all(:proyecto_id => p.id, :codigo => self.codigo) if p.estado_actual.nil? || !p.estado_actual.definicion_estado.cerrado
    end if self.proyecto && self.proyecto.convenio?
  end

 
end
