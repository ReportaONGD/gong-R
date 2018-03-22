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
# agente

class Agente < ActiveRecord::Base

  before_destroy :verificar_borrado

  belongs_to :moneda_principal, :class_name => "Moneda", :foreign_key => "moneda_id"
  belongs_to :moneda_intermedia, :class_name => "Moneda", :foreign_key => "moneda_intermedia_id"
  belongs_to :pais
  belongs_to :tipo_agente

  has_many :convocatoria, :order => :fecha_publicacion, :dependent => :destroy
  has_many :tarea, :order => "fecha_inicio"
  has_many :agente_x_moneda, :dependent => :destroy
  has_many :moneda, :through => :agente_x_moneda
  has_many :libro
  has_many :proveedor, :dependent => :destroy, :order => "nombre"
  has_many :ingreso, :dependent => :destroy
  has_many :presupuesto_ingreso, :dependent => :destroy
  has_many :etapa, :dependent => :destroy, :order => "fecha_inicio"
  has_many :usuario_x_agente, :dependent => :destroy
  has_many :usuario, :through => :usuario_x_agente, :order => "nombre"
  has_many :grupo_usuario_x_agente, :dependent => :destroy
  has_many :grupo_usuario, :through => :grupo_usuario_x_agente, :order => "nombre"
  has_many :gasto_x_agente, :dependent => :destroy
  has_many :transferencia_x_agente, :dependent => :destroy
  has_many :transferencia, :through => :transferencia_x_agente
  has_many :presupuesto_x_agente, :dependent => :destroy
  has_many :presupuesto, :dependent => :destroy
  has_many :proyecto_x_financiador, :dependent => :destroy
  has_many :proyecto_x_implementador, :dependent => :destroy
  # Proyectos en los que el agente es gestor de los fondos
  has_many :proyecto_gestor, class_name: Proyecto, foreign_key: :gestor_id, order: "proyecto.nombre"
  # Proyectos en los que el agente es implementador
  has_many :proyecto_implementador, :through => :proyecto_x_implementador, :order => "proyecto.nombre", :source => :proyecto
  # Proyectos en los que el agente es financiador
  has_many :proyecto_financiador, :through => :proyecto_x_financiador, :order => "proyecto.nombre", :source => :proyecto
  has_many :empleado

  # A investigar como averiguar los proyectos gestionados por el agente (posibilidad: meter un campo agente_gestor_id en proyecto)
  #has_many :proyecto_gestionado, :order => "nombre", :source => :proyecto, :through => :libro, :conditions => Proc.new{ ["proyecto.libro_id = libro.id"] }

  has_many :partida_financiacion, :order => "codigo", :dependent => :destroy
  has_many :subpartida, :dependent => :destroy
  has_many :documento #, :through => :espacio
  has_one :espacio, :dependent => :destroy

  # Codigo de contabilidad del agente financiador (hay uno por cada delegacion)
  has_many :cuenta_contable, :as => :elemento_contable
  # Codigos de contabilidad de la delegacion
  has_many :cuentas_contables_delegacion, :class_name => "CuentaContable"

  has_many :contrato, :dependent => :destroy

  validate :nombre_mayusculas
  validates_uniqueness_of :nombre, :message => _("Nombre repetido."), :case_sensitive => false
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :pais_id, :message => _("País") + " " + _("no puede estar vacío."), :unless => :sistema

  after_save :cambiar_tasas_cambio, :actualiza_espacio, :crea_convocatoria
  after_destroy :verificar_borrado, :borrar_espacio


  def nombre_mayusculas
    self.nombre = self.nombre.upcase if self.nombre
    # Aprovechamos y quitamos el pais a los financiadores puros
    #self.pais_id = nil unless self.implementador
  end

  # Devuelve el nombre (esto es necesario para hacer comunes los helpers en el listado de subcuentas)
  def codigo_nombre
    return self.nombre
  end

  def partida
    Partida.all
  end

	# Devuelve los proyectos (evitando convenios) de los cuales es implementador y que estan abiertos
  def proyecto_implementador_abierto
    proyecto_implementador.collect{ |p| [p.nombre, p.id] if p.estado_actual && p.estado_actual.definicion_estado.aprobado && !p.convenio? } 
  end
  def proyectos_ejecucion etp=nil
    proyecto_implementador.select { |p| p.estado_actual && p.estado_actual.definicion_estado.aprobado && !p.convenio? }
  end 

  # Para una etapa dada, todos aquellos proyectos en los que el agente interviene como implementador
  def proyectos_vinculados etp=nil
    pi = proyecto_implementador.collect do |p|
      p if !p.convenio? &&
           (  etp.nil? || p.etapa.empty? ||
              (p.fecha_de_inicio >= etp.fecha_inicio && p.fecha_de_inicio <= etp.fecha_fin) ||
              (p.fecha_de_fin >= etp.fecha_fin && p.fecha_de_fin <= etp.fecha_fin) ||
              (p.fecha_de_inicio < etp.fecha_inicio && p.fecha_de_fin > etp.fecha_fin) )
    end
    return pi.compact!
  end
  # Para una etapa dada, todos aquellos agentes que intervienen en proyectos como implementadores
  def implementadores_vinculados etp=nil
    pi = []
    proyectos_vinculados(etp).collect do |p|
      pi += p.implementador
    end
    return pi.uniq!.sort!{|x,y| x.nombre <=> y.nombre}
  end

	# Genera cuentas (caja y caja chica) para todas las monedas del pais donde actua
  def generar_cuentas
    pais.moneda.each do |mon|
      libro_nombre = (nombre + "-" + mon.abreviatura).capitalize
      l1=Libro.find_or_create_by_nombre_and_moneda_id_and_agente_id_and_tipo_and_pais_id(libro_nombre, mon.id, self.id, "banco", self.pais_id)
      l1.update_attribute(:descripcion, libro_nombre + " - " + self.nombre_completo) if l1 && l1.descripcion.nil?
      l2=Libro.find_or_create_by_nombre_and_moneda_id_and_agente_id_and_tipo_and_pais_id(libro_nombre + "-C", mon.id, self.id, "caja \"chica\"", self.pais_id)
      l2.update_attribute(:descripcion, libro_nombre + "-C - " + self.nombre_completo) if l2 && l2.descripcion.nil?
    end
  end

  # Copia el mapeo de partidas de financiador desde otro agente
  def copiar_mapeo_desde agt=nil
    if self.financiador && agt && agt.class.name == "Agente" && agt.financiador && (parts_f = agt.partida_financiacion.where(proyecto_id: nil)).size > 0
      # Primero borramos lo que haya
      self.partida_financiacion.where(proyecto_id: nil).destroy_all
      # Y luego vamos copiando el mapeo
      parts_f.each do |pf|
        mipf = pf.dup
        # Si la partida tiene madre, averiguamos cual es
        mipf.partida_financiacion_id = nil
        if pf_madre = pf.partida_financiacion_madre
          mipf_madre = PartidaFinanciacion.find_by_agente_id_and_codigo(self.id, pf_madre.codigo)
          mipf.partida_financiacion_id = mipf_madre.id if mipf_madre
        end
        # Guardamos los cambios
        mipf.update_attributes agente_id: self.id
        pf.partida_x_partida_financiacion.each { |pxpf| mipf.partida_x_partida_financiacion.create(:partida_id => pxpf.partida_id) } if mipf.errors.empty?
      end
    end
  end

        # Devuelve el rol del usuario en el agente (o false si no lo tiene)
  def usuario_autorizado? user=nil
    obj = usuario_x_agente.order(:grupo_usuario_id).find_by_usuario_id(user.id) if user && user.class.name == "Usuario"
    return obj ? obj.rol : false
  end

  # Devuelve si el usuario esta asignado con un rol de privilegios especiales
  def usuario_admin? user=nil
    return user.privilegios_especiales?(self) if user.class.name == "Usuario"
  end

	# Devuelve los usuarios_x_ vinculados directamente (no a traves de grupo)
  def usuario_x_vinculado
    return usuario_x_agente.where(:grupo_usuario_id => nil) 
  end

	# Devuelve lo presupuestado en una etapa (aplicando TC)
  def presupuesto_etapa etap
    if etap && etap.class.name == "Etapa"
      return presupuesto.includes("tasa_cambio").where("presupuesto.tasa_cambio_id = tasa_cambio.id").where(:etapa_id => etap.id).sum("importe*tasa_cambio").to_f
    end
  end
	# Devuelve lo gastado en una etapa (aplicando TC)
  def gasto_etapa etap
    if etap && etap.class.name == "Etapa"
      return Gasto.includes("tasa_cambio_agente").where("agente_tasa_cambio_id = tasa_cambio.id").where(:agente_id => self.id, :fecha => etap.fecha_inicio..etap.fecha_fin).sum("importe*tasa_cambio").to_f
    end 
  end

  # Devuelve un array de totales de importes de contratos segun estados de los contratos
  # Se le puede pasar un hash de condiciones
  def totales_contratos condiciones={}
    totales = []

    todos = contrato.includes("workflow_contrato").where(condiciones) 
    abr_mon = moneda_principal.abreviatura

    # Total presupuestado
    contratos = todos
    # Usamos fecha_fin del periodo de contrato porque se asume que ahi es cuando se produce el gasto del hito
    importe_presupuestado = contratos.joins(:periodo_contrato, agente: [etapa: :tasa_cambio]).
                                      where("tasa_cambio.moneda_id = contrato.moneda_id AND objeto = 'presupuesto'").
                                      where("etapa.fecha_inicio <= periodo_contrato.fecha_fin AND etapa.fecha_fin >= periodo_contrato.fecha_fin").
                                      sum("periodo_contrato.importe * tasa_cambio.tasa_cambio")
    totales.push( nombre: "presupuesto_total", etiqueta: _("Total Presupuestado"), importe: importe_presupuestado.to_f, moneda: abr_mon)

    # Importe comprometido (presupuestos aprobados)
    contratos = todos.where("workflow_contrato.aprobado" => true)
    importe_comprometido = contratos.joins(:periodo_contrato, agente: [etapa: :tasa_cambio]).
                                     where("tasa_cambio.moneda_id = contrato.moneda_id AND objeto = 'presupuesto'").
                                     where("etapa.fecha_inicio <= periodo_contrato.fecha_fin AND etapa.fecha_fin >= periodo_contrato.fecha_fin").
                                     sum("periodo_contrato.importe * tasa_cambio.tasa_cambio")
    totales.push( nombre: "presupuesto_aprobado", etiqueta: _("Comprometido"), importe: importe_comprometido.to_f, moneda: abr_mon)

    # Importe ejecucion (gastos de contratos aprobados en ejecucion)
    gastos = Gasto.where(agente_id: self.id).joins(gasto_x_contrato: {contrato: :workflow_contrato}).
                   where(condiciones).where("workflow_contrato.aprobado" => true)
    importe_ejecutado = gastos.joins(:tasa_cambio_agente).
                   sum("gasto.importe * tasa_cambio")
    totales.push( nombre: "gasto_ejecutado", etiqueta: _("Total Ejecutado"), importe: importe_ejecutado.to_f, moneda: abr_mon)

    # Importe pendiente (presupuesto - gastos, de contratos aprobados en ejecucion)
    gastos = Gasto.where(agente_id: self.id).joins(gasto_x_contrato: {contrato: :workflow_contrato}).
                   where(condiciones).where("workflow_contrato.aprobado" => true, "workflow_contrato.cerrado" => false)
    contratos = todos.where("workflow_contrato.aprobado" => true, "workflow_contrato.cerrado" => false)
    importe_ejecutado = gastos.joins(:tasa_cambio_agente).
                               sum("gasto.importe * tasa_cambio")
    importe_ppto_ejec = contratos.joins(:periodo_contrato, agente: [etapa: :tasa_cambio]).
                                  where("tasa_cambio.moneda_id = contrato.moneda_id AND objeto = 'presupuesto'").
                                  where("etapa.fecha_inicio <= periodo_contrato.fecha_fin AND etapa.fecha_fin >= periodo_contrato.fecha_fin").
                                  sum("periodo_contrato.importe * tasa_cambio.tasa_cambio")
    totales.push( nombre: "pendiente_ejecucion", etiqueta: _("Pendiente Ejecución"), importe: (importe_ppto_ejec.to_f - importe_ejecutado.to_f), moneda: abr_mon)

    return totales
  end

  # Devuelve el numero de contratos de cada tipo (aplicando las condiciones enviadas si es necesario
  def num_contratos condiciones={}
    todos = contrato.joins(:workflow_contrato).where(condiciones)

    num = { total:    { cantidad: todos.count, etiqueta: _("%d contratos en total")%[todos.count] } }
    cantidad = todos.where("workflow_contrato.aprobado" => true).count
    num[:aprobados] = { cantidad: cantidad, etiqueta: _("%d en formulación")%[cantidad] }
    cantidad = todos.where("workflow_contrato.aprobado" => true).count
    num[:ejecucion] = { cantidad: cantidad, etiqueta: _("%d en ejecución")%[cantidad] }
    cantidad = todos.where("workflow_contrato.cerrado" => true).count 
    num[:cerrados]  = { cantidad: cantidad, etiqueta: _("%d cerrados")%[cantidad] }

    return num
  end

	# Devuelve un hash con el arqueo de todos los libros del agente en la etapa indicada 
  def remanente etap
    remanentes = {} 
    if etap && etap.class.name == "Etapa" && etap.etapa_siguiente
      # Recorre todas las cuentas del agente
      self.libro.each do |l|
        remanentes[l.id] = l.arqueo([], etap.fecha_inicio, etap.fecha_fin)
      end 
    end
    return remanentes
  end

	# Genera transferencias en la etapa siguiente a la indicada con los remanentes de esta
  def generar_remanente etap
    errores = false
    # Primero borramos todas las transferencias de remanentes de la etapa siguiente para todos los libros
    self.libro.each do |l|
      Transferencia.all(:conditions => {:proyecto_id => nil, :fecha_recibido => etap.etapa_siguiente.fecha_inicio, :remanente => true}).each {|t| t.destroy}
    end
    # Y recorremos todos los remanentes (si los hay) para ir aplicandolos libro a libro
    remanentes = self.remanente etap
    if remanentes.count > 0
      remanentes.keys.each do |libro_id|
        total = remanentes[libro_id][:entrante] - remanentes[libro_id][:saliente]
        if total != 0
          t = Transferencia.new(	:remanente => true, :tipo => "remanente",
					:libro_destino_id => libro_id,
					:fecha_recibido => etap.etapa_siguiente.fecha_inicio,
					:importe_recibido => total, :importe_cambiado => total,
					:observaciones => _("Remanente") + " " + etap.nombre )
          t.save
          errores = true unless t.errors.empty?
          errors[:base] << ( _("Problemas generando transferencia de remanente para el libro") + ": " + self.libro.find_by_id(libro_id).nombre) unless t.errors.empty?
          logger.info "---------------> Error generando transferencia de remanente en agente " + t.errors.inspect unless t.errors.empty?
        end
      end
    end
    # Si no se han producido errores...
    unless errores
      # ... indica a la etapa que los saldos estan ok
      etap.saldos_transferidos = true
      etap.save
      # ... y a la etapa siguiente (si existe y esta cerrada) que tiene que revisar los suyos
      if (etap_siguiente = etap.etapa_siguiente) && etap_siguiente.cerrada
        etap_siguiente.saldos_transferidos = false
        etap_siguiente.save
      end
    end
  end

  private

  def cambiar_tasas_cambio
    # Si se cambia de pais, incluye las monedas adecuadas
    self.pais.moneda.each { |m| AgenteXMoneda.find_or_create_by_agente_id_and_moneda_id(self.id, m.id) } if pais_id_changed?
    # Mete la moneda como propia si se cambia
    AgenteXMoneda.find_or_create_by_agente_id_and_moneda_id(self.id, self.moneda_id) if moneda_id_changed?
    # Y lo mismo para la divisa
    AgenteXMoneda.find_or_create_by_agente_id_and_moneda_id(self.id, self.moneda_intermedia_id) if moneda_intermedia_id_changed? && moneda_intermedia_id
    # Para modificaciones de agente que incluyan moneda principal, actualiza las tasas de cambio
    self.etapa.each { |e| TasaCambio.cambia_moneda(e) } if id_was && moneda_id_changed?
  end

  def verificar_borrado
    errors.add( "presupuesto",_("hay líneas de presupuesto asignadas")) unless self.presupuesto.empty?
    errors.add( "presupuesto",_("hay líneas de presupuesto financiadas")) unless self.presupuesto_x_agente.empty?
    errors.add( "gasto", _("hay gastos ejecutados")) unless Gasto.where(agente_id: self.id).empty?
    errors.add( "gasto", _("hay gastos financiados")) unless self.gasto_x_agente.empty?
    errors.add( "libro", _("hay cuentas bancarias o cajas chicas")) unless self.libro.empty?
    errors.add( "transferencia", _("hay transferencias")) unless self.transferencia_x_agente.empty?
    self.convocatoria.each do |conv|
      errors.add( "convocatoria", _("la convocatoria %{conv} tiene proyectos asignados")%{:conv => conv.nombre}) unless conv.proyecto.empty?
    end
    errors[:base] << ( _("Un agente tiene que estar vacío para poder ser borrado.") ) unless errors.empty?
    return errors.empty?
  end

  def crea_convocatoria
    if self.financiador && !self.implementador && !self.sistema
      nombre_conv = self.nombre + "-" + _("General")
      Convocatoria.find_or_create_by_codigo_and_nombre_and_agente_id(nombre_conv, nombre_conv, id)
    end
  end

  def actualiza_espacio
    espacio_padre = Espacio.find_by_nombre_and_espacio_padre_id("Socias Locales", pais.espacio.id) if pais && pais.espacio && implementador && socia_local
    espacio_padre = Espacio.find_by_nombre_and_espacio_padre_id("Delegaciones", pais.espacio.id) if pais && pais.espacio && implementador && !socia_local
    tipo = "agente" if implementador
    espacio_padre = Espacio.find_by_nombre_and_espacio_padre_id("Financiadores",nil) if financiador && !implementador
    tipo = "financiador" if financiador && !implementador
    if espacio_padre
      if espacio
        #puts "------> Hay espacio"
        espacio.update_attributes :nombre => nombre, :espacio_padre_id => espacio_padre.id
        espacio.errors.each {|e,m|  errors.add "", m}
      else
        #puts "------> No hay espacio"
        espacio = Espacio.create :nombre => nombre, :agente_id => self.id, :espacio_padre_id => espacio_padre.id, :descripcion => _("Espacio raíz del %{agente}: %{nombre}") % {:agente => tipo, :nombre => nombre}
        #puts "-----------> ERROR: " + espacio.errors.inspect unless espacio.errors.empty?
        espacio.errors.each {|e,m|  errors.add "", m}
      end
      # Actualiza los espacios automaticos
      if espacio && espacio.errors.empty?
        if implementador && !socia_local
          for esp in Espacio.find_all_by_definicion_espacio_agente_and_espacio_padre_id(true,nil)
            ne = Espacio.find_or_create_by_nombre_and_espacio_padre_id_and_definicion_espacio_agente_id(esp.nombre,espacio.id,esp.id)
            # Activamos el bit de ocultar
            ne.update_attributes :ocultar => esp.ocultar if ne && ne.errors.empty?
            ne.errors.each {|e,m|  errors.add "", m}
          end
        end
        if implementador && socia_local
          for esp in Espacio.find_all_by_definicion_espacio_socia_and_espacio_padre_id(true,nil)
            ne = Espacio.find_or_create_by_nombre_and_espacio_padre_id_and_definicion_espacio_socia_id(esp.nombre,espacio.id,esp.id)
            # Activamos el bit de ocultar
            ne.update_attributes :ocultar => esp.ocultar if ne && ne.errors.empty?
            ne.errors.each {|e,m|  errors.add "", m}
          end
        end
        if financiador && !implementador
          for esp in Espacio.find_all_by_definicion_espacio_financiador_and_espacio_padre_id(true,nil)
            ne = Espacio.find_or_create_by_nombre_and_espacio_padre_id_and_definicion_espacio_financiador_id(esp.nombre,espacio.id,esp.id)
            # Activamos el bit de ocultar
            ne.update_attributes :ocultar => esp.ocultar if ne && ne.errors.empty?
            ne.errors.each {|e,m|  errors.add "", m}
          end
        end
      end
    else
      logger.info "ERROR: No existe el espacio padre para el agente " + nombre
    end
  end

  def borrar_espacio
    if espacio
      if implementador && !socia_local
        for esp in Espacio.find_all_by_definicion_espacio_agente(true)
          esp = Espacio.find_by_espacio_padre_id_and_definicion_espacio_agente_id(espacio.id,esp.id)
          esp.destroy if esp
          esp.errors.each {|e,m|  errors.add "", m} if esp
        end
      end
      if implementador && socia_local
        for esp in Espacio.find_all_by_definicion_espacio_socia(true)
          esp = Espacio.find_by_espacio_padre_id_and_definicion_espacio_socia_id(espacio.id,esp.id)
          esp.destroy if esp
          esp.errors.each {|e,m|  errors.add "", m} if esp
        end
      end
      if financiador && !implementador
        for esp in Espacio.find_all_by_definicion_espacio_financiador(true)
          esp = Espacio.find_by_espacio_padre_id_and_definicion_espacio_financiador_id(espacio.id,esp.id)
          esp.destroy if esp
          esp.errors.each {|e,m|  errors.add "", m} if esp
        end
      end
      espacio.destroy
      espacio.errors.each {|e,m|  errors.add "", m}
    end
  end
  
end
  

