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
class Presupuesto < ActiveRecord::Base

  # Variable temporal donde recoger la modificacion del nombre de la subpartida
  # Esto lo hacemos asi para evitar que se busque una subpartida sin haber obtenido
  # antes la partida_id (en el proceso del update_attributes)
  @subpartida_nombre_tmp = nil

  before_destroy :verifica_etapa

  belongs_to :moneda
  belongs_to :partida
  belongs_to :libro
  belongs_to :agente
  belongs_to :pais
  belongs_to :subpartida
  belongs_to :proyecto
  belongs_to :etapa
  belongs_to :tasa_cambio

  has_many :presupuesto_x_proyecto, :dependent => :destroy
  has_many :presupuesto_x_agente, :dependent => :destroy
  has_many :financiador, :source => :agente, :through => :presupuesto_x_agente
  has_many :presupuesto_x_actividad, :dependent => :destroy
  has_many :actividad, :through => :presupuesto_x_actividad

  has_many :presupuesto_detallado, :dependent => :destroy

  # Auditado de modificaciones, comentarios y marcado 
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy
  belongs_to :marcado

  # Asociacion un poco rara pero que nos viene bien
  has_many :partida_x_partida_financiacion, :foreign_key => :partida_id, :primary_key => :partida_id

  validates_presence_of :moneda, :message => _("Moneda") + " " + _("no puede estar vacía.")
  #validates_presence_of :proyecto, :message => _("Proyecto") + _(" no puede estar vacío.")
  validates_presence_of :agente, :message => _("Agente") + " " + _("no puede estar vacío.")
  validates_presence_of :partida, :message => _("Partida") + " " + _("no puede estar vacía.")
  validates_presence_of :concepto, :message => _("Concepto") + " " + _("no puede estar vacío.")
  validates_presence_of :etapa, :message => _("Etapa") + " " + _("no puede estar vacía.")
  validates_numericality_of :importe, :greater_than => 0, :message => _("Importe") + " " + _("no puede estar vacío.")
  validates_numericality_of :numero_unidades, :greater_than => 0, :message => _("Numero unidades") + " " + _("no puede estar vacío.")

  # Validación de concepto para presupuesto de proyecto
  # Desactivado para optimizar rendimiento
  #validates_uniqueness_of :concepto, :scope => [:proyecto_id], :message => _("Concepto repetido") + " (%{value})", :unless => "proyecto_id.nil?"
  # Validación de concepto para presupuesto de agente
  validates_uniqueness_of :concepto, :scope => [:agente_id, :etapa_id, :partida_id, :subpartida_id], :message => _("Concepto repetido") + " (%{value})", :if => "proyecto_id.nil? && empleado_id.nil?"

  validate :comprueba_subpartida, :verifica_etapa, :verifica_pais
  before_save :adaptacion_datos
  after_create :dividir_por_mes

  class << self
    def sin_partida_financiador(proyecto)
      where (["presupuesto.proyecto_id = ? AND presupuesto.partida_id NOT IN (?)", proyecto, (p=Partida.all(:include => [:partida_x_partida_financiacion], :order => "codigo", :conditions => {"partida_x_partida_financiacion.partida_financiacion_id" => proyecto.partida_financiacion})).size>0 ? p : '' ])
    end
    def sin_actividad(proyecto)
      includes("presupuesto_x_actividad").where('presupuesto_x_actividad.id IS NULL AND presupuesto.proyecto_id = ?',proyecto)
    end
  end


  # Comprueba que el presupuesto tenga pais asignado para los presupuestos de agentes
  def verifica_pais
    # Asignamos el pais del agente si está vacío y es un ppto. de agente
    if self.proyecto_id.nil?
      self.pais_id = self.agente.pais_id if self.pais_id.nil? && self.agente
      errors.add :base, _("País") + " " + _("no puede estar vacío.") if self.pais_id.nil?
    end
  end

    # Para presupuestos de agentes, comprueba que la etapa no este cerrada o sea no presupuestable
  def verifica_etapa
    e_old = Etapa.find_by_id(etapa_id_was) if self.etapa_id_was
    if self.proyecto.nil? && (self.etapa.cerrada || !self.etapa.presupuestable || (self.etapa_id_was && (e_old.cerrada|| !e_old.presupuestable) ) )
      errors.add(_("Etapa"), _("La etapa esta cerrada. No se pueden modificar presupuestos."))
      return false
    else
      return true
    end
  end

  def comprueba_subpartida
    # Si se ha modificado el nombre de la subpartida
    if @subpartida_nombre_tmp
      # Si esta vacio, le quita la subpartida cuando la linea de presupuesto exista previamente
      if @subpartida_nombre_tmp == ""
        logger.info "============> ANULANDO SUBPARTIDA PARA EL PRESUPUESTO " + self.inspect if self.id
        self.subpartida_id = nil if self.id
      # Si tiene contenido, buscamos la subpartida adecuada
      else
        # Para proyectos
        self.subpartida = ( self.proyecto.subpartida.find_by_nombre_and_partida_id(@subpartida_nombre_tmp,self.partida_id) || Subpartida.new(:proyecto_id => self.proyecto_id, :partida_id => self.partida_id, :nombre => @subpartida_nombre_tmp) ) if self.proyecto_id
        # Para agentes
        self.subpartida = ( self.agente.subpartida.find_by_nombre_and_partida_id(@subpartida_nombre_tmp,self.partida_id) || Subpartida.new(:agente_id => self.agente_id, :partida_id => self.partida_id, :nombre => @subpartida_nombre_tmp) ) if self.proyecto_id.nil? && self.agente_id
        # Si la subpartida es nueva trata de guardarla en busca de errores
        if self.subpartida && self.subpartida.id.nil?
          self.subpartida.save
          errors.add(_("Subpartida"), _("La subpartida ya está asociada a otra partida.")) unless self.subpartida.errors.empty?
          return false unless self.subpartida.errors.empty?
        end
      end
    end
  end

  def adaptacion_datos
    # Concepto en mayusculas
    self.concepto = self.concepto.upcase
    # Cambia la tasa de cambio si es nuevo o se ha actualizado etapa o moneda
    if (self.id.nil? || self.etapa_id_changed? || self.moneda_id_changed?)
      objeto = (self.proyecto || self.agente)
      tc = TasaCambio.tasa_cambio_para_presupuesto(self.etapa,self.moneda_id)
      self.tasa_cambio_id = tc ? tc.id : nil
    end
  end
  
  def subpartida_nombre
    subpartida.nombre if subpartida
  end 

  # Guarda el nombre de la subpartida en una variable temporal para asignarla en la validacion 
  def subpartida_nombre=(nombre)
    @subpartida_nombre_tmp = nombre.to_s.upcase
  end

  #Metodo especifico creado para el ruport y la exportacion
  def moneda_abreviatura
    return Moneda.find(self.moneda_id).abreviatura if self.moneda_id
  end


  #Metodo especifico creado para el ruport y la exportacion
  def agente_nombre
    return Agente.find(self.agente_id).nombre if self.agente_id
  end

  # Devuelve el importe en la moneda base (principal) del proyecto/agente
  def importe_ml
    return self.importe * self.tasa_cambio
  end
  def importe_en_base
    objeto = self.proyecto || self.agente
    ixtc = self.importe_ml
    return ('%.2f' % ixtc).to_s + " " + objeto.moneda_principal.abreviatura if ixtc
  end

  # Devuelve el importe en la divisa del proyecto/agente
  def importe_divisa
    return self.importe * self.tasa_cambio_divisa
  end
  def importe_en_divisa
    divisa = (self.agente || self.proyecto).moneda_intermedia
    ixtc = self.importe_divisa if divisa
    return ('%.2f' % ixtc).to_s + " " + divisa.abreviatura if divisa && ixtc
  end

  # Devuelve un array con los importes por actividad
  def importes_por_actividades
    salida = Array.new
    pxas = presupuesto_x_actividad.all
    pxas.each {|pxa| salida.push( pxa.actividad.codigo + ": " + pxa.importe.to_s ) }
    return salida
  end

  # Devuelve un array con los importes por financiador
  def importes_por_financiadores
    salida = Array.new
    pxfs = presupuesto_x_agente.all
    pxfs.each {|pxf| salida.push( pxf.agente.nombre + ": " + pxf.importe.to_s ) }
    return salida
  end

  # Devuelve un array con los importes por proyectos
  def importes_por_proyectos
    salida = Array.new
    pxp = presupuesto_x_proyecto.all
    pxp.each do |pxp| 
      nombre = pxp.proyecto_id.nil? ? "Imputado al agente" : pxp.proyecto.nombre 
      salida.push( nombre + ": " + pxp.importe.to_s )
    end
    return salida
  end



  # Actualiza el listado de agentes con los que se ha asociado el presupuesto para un determinado proyecto.
  def actualizar_presupuesto_x_agente listado
    presupuesto_x_agente.clear
    listado.each do |key, value|
      pxa = presupuesto_x_agente.create(value)
      errors.add("", pxa.errors.inject('') {|total, e| total + e[1] + " " }) unless pxa.errors.empty?
    end   
    if listado.inject(0) {|suma, value| suma + moneda_a_float(value.pop[:importe_convertido])} != self.importe
      errors.add(_('Importes'), _("Los importes de los financiadores no suman el importe total del presupuesto."))        
    end
  end

  # Actualiza el listado de proyectos con los que se ha asociado el presupuesto para un determinado agente.
  def actualizar_presupuesto_x_proyectos listado
    presupuesto_x_proyecto.clear
    listado.each do |key, value|
      if value[:importe] && value[:importe].to_f != 0 
        pxa = presupuesto_x_proyecto.create(value)
        errors.add("", pxa.errors.inject('') {|total, e| total + e[1] + " " }) unless pxa.errors.empty?
      end
    end        
    if listado.inject(0) {|suma, value| suma + moneda_a_float(value.pop[:importe])} != self.importe
      errors.add(_('Importes'), _("Los importes de los proyectos no suman el importe total del presupuesto."))        
    end
  end

  # Actualiza el listado de actividades con los que se ha asociado el presupuesto para un determinado proyecto.
  def actualizar_presupuesto_x_actividad listado
    presupuesto_x_actividad.clear
    listado.each do |key, value|
      pxa = presupuesto_x_actividad.create(value)
      errors.add("", pxa.errors.inject('') {|total, e| total + e[1] + " " }) unless pxa.errors.empty?
    end
    if  listado.inject(0) {|suma, value| suma + moneda_a_float(value.pop[:importe_convertido])} != self.importe
      errors.add(_('Importes'), _("Los importes de las actividades no suman el importe total del presupuesto."))        
    end
  end

  # Actualiza el detalle del presupuesto.
  def actualizar_presupuesto_detallado listado
    # Actualiza el detalle solo si se puede (hacemos una comparacion con false
    if verifica_etapa
      presupuesto_detallado.clear
      listado.each do |mes, value|
        presupuesto_detallado.create(value) unless value[:importe] == ""
      end
      errors.add(_('Porcentajes'),_("La suma del detalle no coincide con la importe de la linea del presupuesto. Vuelva a editar el detalle para corregirlo.")) unless self.importe == presupuesto_detallado.inject(0) {|sum,p| sum+(p.importe||0.0)}
    end
  end

  def dividir_por_actividades actividades
    unless actividades.size == 0
      detalle = Hash.new
      importe_x_actividad, resto_importe = importe.divmod(actividades.size)
      numero_unidades_x_actividad, resto_numero_unidades = numero_unidades.divmod(actividades.size) 
      for actividad in actividades
        if actividad.class.name == "Actividad"
          if actividad == actividades.last
            importe_x_actividad += resto_importe
            numero_unidades_x_actividad += resto_numero_unidades
          end
          detalle[actividad.id] = { :importe_convertido => importe_x_actividad, :numero_unidades => numero_unidades_x_actividad , :actividad_id => actividad.id } 
        end
      end
      actualizar_presupuesto_x_actividad detalle
    end
  end

  def dividir_por_mes fecha_inicio=nil, fecha_fin=nil, evitar=nil
     fecha_inicio ||= self.etapa.fecha_inicio if self.etapa
     fecha_fin ||= self.etapa.fecha_fin if self.etapa
     # Toma los valores segun evitemos meses o no
     meses_repartir = evitar ? 0 : etapa.meses
     ultimo_mes = evitar ? 0 : etapa.periodos
     # Si evitamos meses, hacemos los calculos de el total y el ultimo
     evitar.each do |m|
       if m[1] == "false"
         ultimo_mes = m[0].to_i
         meses_repartir += 1
       end
     end if evitar
     detalle, fecha = Hash.new,  Date.new(fecha_inicio.year, fecha_inicio.month, 1)
     # Hacemos el ajuste en base a los centimos/centavos y no a las unidades de moneda
     # Si no tenemos meses a repartir, el divmod daria un error...
     unless meses_repartir == 0
       importe_x_mes, resto = (importe * 100).divmod(meses_repartir)
     else
       # No hay meses completos, asi que dejamos el resto para los dias sueltos
       importe_x_mes, resto = 0.0, (importe*100) if etapa.meses == 0
       # Si hay mas de un mes, pero se deja sin meses a repartir... sera por algo...
       importe_x_mes, resto = 0.0, 0.0 unless etapa.meses == 0
     end
     # Volvemos a multiplicar por 100 para obtener unidades de moneda
     importe_x_mes, resto = importe_x_mes/100, resto/100
     for mes in 1..(etapa.periodos)
       # Si estamos evitando algunos meses, comprobamos si este es uno
       if evitar && evitar["#{mes}"] == "true"
         detalle[mes] = { :importe => 0, :fecha_inicio => fecha >> (mes -1), :fecha_fin => fecha_fin, :mes => mes }
       else
         # Para el último, hacemos un ajuste fino
         if mes != ultimo_mes 
           detalle[mes] = { :importe => importe_x_mes, :fecha_inicio => (mes == 1 ? fecha_inicio : fecha >> (mes - 1)), :fecha_fin => (fecha >> mes) - 1, :mes => mes }
         # Para los intermedios...
         else 
           importe = resto + ( (evitar ||etapa.periodos == etapa.meses) ? importe_x_mes : 0)
           detalle[mes] = { :importe => importe, :fecha_inicio => fecha >> (mes -1), :fecha_fin => fecha_fin, :mes => mes }  
         end
       end
     end
     actualizar_presupuesto_detallado detalle unless etapa.cerrada
  end

  # Comprobacion del reparto por financiadores 
  def comprobar_financiadores
    presupuesto_x_agente.sum(:importe).round(2) == self.importe
  end
  

  # Comprobacion del reparto por actividades
  def comprobar_actividades
    presupuesto_x_actividad.sum(:importe).round(2) == self.importe
  end

  # Comprueba si el detalle del presupuesto se ha configurado adecuadamente.
  def comprobar_presupuesto_detallado
    presupuesto_detallado.sum(:importe).round(2) == self.importe
  end

  # Comprobacion del reparto por proeyctos  
  def comprobar_proyectos
    presupuesto_x_proyecto.sum(:importe).round(2) == self.importe
  end

  # Devuelve si el presupuesto esta dividido entre todas las actividades del proyecto
  # Se utiliza un parametro 'proy' inutil por compatibilidad con el metodo de gastos
  def todas_actividades? proy=nil
    if etapa_id
      return presupuesto_x_actividad.size == proyecto.actividad.includes("actividad_x_etapa").where("actividad_x_etapa.etapa_id = ?", etapa_id).size if proyecto 
    else
      return presupuesto_x_actividad.size == proyecto.actividad.size if proyecto
    end
  end



  # Devuelve la tasa de cambio para la línea de presupuesto (si existe)
  def tasa_cambio
    tc = TasaCambio.find_by_id(self.tasa_cambio_id)
    return (tc ? tc.tasa_cambio : 0.0)
  end

  # Devuelve la tasa de cambio a divisa para la línea de presupuesto (si existe)
  def tasa_cambio_divisa
    tc = TasaCambio.find_by_id(self.tasa_cambio_id)
    return (tc ? tc.tasa_cambio_moneda_intermedia : 0.0)
  end

  # Devuelve un texto amigable para la tasa de cambio del presupuesto
  def cadena_tasa_cambio
    moneda_principal = (self.etapa.agente || self.etapa.proyecto).moneda_principal
    return self.tasa_cambio.to_s + " " + self.moneda.abreviatura + "/" + moneda_principal.abreviatura
  end

  # Devuelve un texto amigable para la tasa de cambio a divisa del presupuesto
  def cadena_tasa_cambio_divisa
    divisa = (self.etapa.agente || self.etapa.proyecto).moneda_intermedia
    return self.tasa_cambio_divisa.to_s + " " + self.moneda.abreviatura + "/" + divisa.abreviatura if divisa
  end
  #--
  # FINDERS complicados... Mas alla de ActiveRecordBase
  # ++

  # Busqueda creada manualmente para los detalles de busquedas especificas que no cubre el find habitual de ActiveRecord.
  def self.busqueda campos, condiciones, asociacion, agrupado, ordenado
    consulta = " SELECT " + campos + " FROM presupuesto  "
    consulta += asociaciones asociacion
    consulta += " WHERE " + merge_conditions(condiciones) if condiciones
    consulta += " GROUP BY " + agrupado if agrupado
    consulta += " ORDER BY " + ordenado if ordenado
    return find_by_sql consulta 
  end
  
  # Cutrada para sustituir el include para el metodo busqueda.
  def self.asociaciones asociacion
    asociacion.inject(' ') do |suma, elemento|
      case elemento
        # when :presupuesto_x_proyecto
        # suma + ' LEFT JOIN presupuesto_x_proyecto on presupuesto_x_proyecto.presupuesto_id = presupuesto.id'
        #when :tasa_cambio_presupuesto
        #suma + ' LEFT JOIN tasa_cambio_presupuesto on tasa_cambio_presupuesto.presupuesto_id = presupuesto.id'
        when :presupuesto_x_agente
        suma + ' LEFT JOIN presupuesto_x_agente on presupuesto_x_agente.presupuesto_id = presupuesto.id'
        when :presupuesto_x_actividad
        suma + ' LEFT JOIN presupuesto_x_actividad on presupuesto_x_actividad.presupuesto_id = presupuesto.id'
        when :partida_x_partida_financiacion
        suma + ' LEFT JOIN partida_x_partida_financiacion on partida_x_partida_financiacion.partida_id = presupuesto.partida_id'
        when :partida_financiacion
        suma + ' LEFT JOIN partida_financiacion on partida_financiacion.id = partida_x_partida_financiacion.partida_financiacion_id'
        when :presupuesto_detallado
        suma + ' LEFT JOIN presupuesto_detallado on presupuesto_detallado.presupuesto_id = presupuesto.id'
      end
    end
  end

  # Metodo que iguala algunos valores basicos para procesos de insercion de datos.
  def self.datos_basicos_igualar presupuesto, presupuesto_anterior
    presupuesto.partida = presupuesto_anterior.partida
    presupuesto.etapa_id = presupuesto_anterior.etapa_id
    presupuesto.agente_id = presupuesto_anterior.agente_id
    presupuesto.moneda_id = presupuesto_anterior.moneda_id
    presupuesto.importe = presupuesto_anterior.importe
    presupuesto.coste_unitario = presupuesto_anterior.coste_unitario
    presupuesto.numero_unidades = presupuesto_anterior.numero_unidades
    presupuesto.unidad = presupuesto_anterior.unidad
    presupuesto.subpartida_id = presupuesto_anterior.subpartida_id
  end


  # Permite la ejecucion de metodos de plugins no existentes en el modelo
  def method_missing(method_sym, *arguments, &block)
    clase = nil
    # Primero averigua que plugins tienen la clase "Gasto" y cuales de ellos el metodo pedido
    Plugin.activos.each do |plugin|
      begin
        clase = plugin.clase if eval(plugin.clase)::Presupuesto.respond_to?(method_sym)
      rescue => ex
      end
    end
    # Invoca al ultimo plugin que haya encontrado (o al super si no hay ninguno)
    clase ? eval(clase)::Presupuesto.send(method_sym,self) : super
  end
end
