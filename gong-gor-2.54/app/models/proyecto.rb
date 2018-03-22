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

# ActiveResource que devuelve proyecto desde Alfresco.
class Proyecto < ActiveRecord::Base

  before_destroy :verificar_borrado

  # Relacion con los paises
  has_many :proyecto_x_pais, :dependent => :destroy
  has_many :pais, :through => :proyecto_x_pais

  # Relacion con el proyecto marco al que pertenece
  belongs_to :programa_marco
  # Y con los indicadores generales de seguimiento
  has_many :indicador_general_x_proyecto, dependent: :destroy
  has_many :indicador_general, through: :indicador_general_x_proyecto

  # Otras relaciones
  belongs_to :convocatoria
  has_one :agente, :through => :convocatoria
  belongs_to :moneda_principal, :class_name => "Moneda", :foreign_key => "moneda_id"
  belongs_to :moneda_intermedia, :class_name => "Moneda", :foreign_key => "moneda_intermedia_id"
  has_many :datos_proyecto, :dependent => :destroy
  has_one :espacio, :dependent => :destroy
  has_many :usuario_x_proyecto, :dependent => :destroy
  has_many :usuario, :through => :usuario_x_proyecto, :order => "nombre"
  has_many :grupo_usuario_x_proyecto, :dependent => :destroy
  has_many :grupo_usuario, :through => :grupo_usuario_x_proyecto, :order => "nombre"
  has_many :gasto_x_proyecto, :dependent => :destroy
  has_many :gasto, :through => :gasto_x_proyecto
  has_many :etapa, :dependent => :destroy, :order => "nombre"
  belongs_to :libro_principal, :class_name => "Libro", :foreign_key => "libro_id"
  has_many :libro_x_proyecto, :dependent => :destroy
  has_many :libro, :through => :libro_x_proyecto, :order => "nombre"
  has_many :transferencia
  has_many :presupuesto, :dependent => :destroy
  has_many :definicion_dato, :through => :proyecto_x_definicion_dato
  has_many :proyecto_x_definicion_dato, :dependent => :destroy
  has_many :dato_texto, :dependent => :destroy
  has_many :documento #, :through => :espacio
  has_one  :objetivo_general, :dependent => :destroy
  has_many :objetivo_especifico, :order => "objetivo_especifico.codigo", :dependent => :destroy
  has_many :resultado, :order => "resultado.codigo", :dependent => :destroy
  has_many :actividad, :order => "actividad.codigo", :dependent => :destroy
  has_many :estado, :dependent => :destroy, :include => :definicion_estado
  has_one  :definicion_estado, :through => :estado_actual
  has_one  :estado_actual, :class_name => "Estado", :foreign_key => "proyecto_id", :conditions => ["estado.estado_actual"]
  has_many :tarea, :order => "fecha_inicio", :dependent => :destroy
  has_many :partida_financiacion, :order => "codigo", :dependent => :destroy
  has_many :proyecto_x_moneda, :dependent => :destroy
  has_many :moneda, :through => :proyecto_x_moneda, :uniq => true
  belongs_to :pais_principal, :class_name => "Pais", :foreign_key => "pais_principal_id"

  has_many :proyecto_x_sector_poblacion, :dependent => :destroy
  has_many :sector_poblacion, :through => :proyecto_x_sector_poblacion, :source => :sector_poblacion, :order => "nombre"
  has_many :proyecto_x_area_actuacion, :dependent => :destroy
  has_many :area_actuacion, :through => :proyecto_x_area_actuacion, :source => :area_actuacion, :order => "nombre"
  has_many :proyecto_x_sector_intervencion, :dependent => :destroy
  has_many :sector_intervencion, :through => :proyecto_x_sector_intervencion, :source => :sector_intervencion, :order => "nombre"

  has_many :proyecto_x_financiador, :dependent => :destroy
  has_many :proyecto_x_implementador, :dependent => :destroy
  belongs_to :gestor, :class_name => "Agente", :foreign_key => "gestor_id"
  has_many :implementador, :through => :proyecto_x_implementador, :source => :agente, :order => "nombre"
  has_many :financiador, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre"

  # Financiadores validos para los gastos
  has_many :financiador_gasto, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre", :conditions => {:sistema => false}
  # Con la siguiente linea mostraria los genericos tambien en ejecucion
  #has_many :financiador_gasto, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre"

  # Agrupaciones de financiadores externos
  has_many :financiador_externo_publico, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre",
           :conditions => Proc.new{ ["publico AND (NOT implementador OR implementador IS NULL) AND agente.id != ? AND (NOT local OR agente.pais_id NOT IN (?))",self.agente.id,self.pais.collect{|p| p.id}] }
  has_many :financiador_externo_privado, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre",
           :conditions => Proc.new{ ["(NOT publico OR publico IS NULL) AND (NOT implementador OR implementador IS NULL) AND agente.id != ? AND (NOT local OR agente.pais_id NOT IN (?))",self.agente.id,self.pais.collect{|p| p.id}] }
  has_many :financiador_externo_ong, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre",
           :conditions => Proc.new{ ["implementador AND agente.id != ? AND agente.pais_id NOT IN (?)",self.agente.id,self.pais.collect{|p| p.id}] }

  # Agrupaciones de financiadores locales
  has_many :financiador_local_publico, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre",
           :conditions => Proc.new{ ["publico AND (NOT implementador OR implementador IS NULL) AND agente.id != ? AND (local OR agente.pais_id IN (?))",self.agente.id,self.pais.collect{|p| p.id}] }
  has_many :financiador_local_privado, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre",
           :conditions => Proc.new{ ["(NOT publico OR publico IS NULL) AND (NOT implementador OR implementador IS NULL) AND agente.id != ? AND (local OR agente.pais_id IN (?))",self.agente.id,self.pais.collect{|p| p.id}] }
  has_many :financiador_local_ong, :through => :proyecto_x_financiador, :source => :agente, :order => "nombre",
           :conditions => Proc.new{ ["implementador AND agente.id != ? AND agente.pais_id IN (?)",self.agente.id,self.pais.collect{|p| p.id}] }

  # Agrupaciones de implementadores
  has_many :socio_local, :through => :proyecto_x_implementador, :source => :agente, :order => "nombre",
           :conditions => Proc.new{["agente.id != ? AND agente.pais_id IN (?)",self.gestor_id,self.pais.collect{|p| p.id}]}
  has_many :ongd_agrupacion, :through => :proyecto_x_implementador, :source => :agente, :order => "nombre",
           :conditions => Proc.new{["agente.id = ? OR agente.pais_id NOT IN (?)",self.gestor_id,self.pais.collect{|p| p.id}]}

  has_many :subpartida, :dependent => :destroy
  has_many :partidas_mapeadas, :through => :partida_financiacion, :source => :partida, :order => "partida_financiacion.codigo,partida.codigo"

  # Para cofinanciacion de proyectos
  has_many :proyecto_x_proyecto, :dependent => :destroy
  has_many :proyecto_x_proyecto_cofinanciado, :foreign_key => 'proyecto_cofinanciador_id', :class_name => 'ProyectoXProyecto', :dependent => :destroy
  has_many :proyecto_cofinanciador, :through => :proyecto_x_proyecto, :class_name => 'Proyecto', :order => "nombre"
  has_many :proyecto_cofinanciado, :through => :proyecto_x_proyecto_cofinanciado, :class_name => 'Proyecto', :order => "nombre"

  # Para convenios
  belongs_to :convenio, :class_name => "Proyecto", :foreign_key => "convenio_id"
  has_many :pacs, :class_name => "Proyecto", :foreign_key => 'convenio_id', :order => "nombre", :dependent => :destroy

  # Codigo de contabilidad (hay uno por cada delegacion)
  has_many :cuenta_contable, :as => :elemento_contable, :dependent => :destroy

  has_many :periodo, :dependent => :destroy
  has_many :personal, :dependent => :destroy
  has_many :contrato, :dependent => :nullify

  validate :nombre_mayusculas
  validates_uniqueness_of :nombre, :message => _("Ya existe un proyecto con nombre '%{value}'."), :case_sensitive => false
  validates_presence_of :titulo, :message => _("Título") + " " + _("no puede estar vacío.")
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :convocatoria_id, :message => _("Convocatoria") + " " + ("no puede estar vacía.")
  validates_presence_of :moneda_id, :message => _("Moneda") + " " + _("no puede estar vacía.")
  validates_presence_of :gestor_id, :message => _("Gestor de la subvención") + " " + _("no puede estar vacío.")
  validates_format_of :fecha_limite_peticion_prorroga, :with => /\d{4}-\d{1,2}-\d{1,2}/, :on => :create, :message => _("El formato de la fecha no es correcto."), :allow_blank => true
  validates_format_of :fecha_inicio_aviso_peticion_prorroga , :with => /\d{4}-\d{1,2}-\d{1,2}/, :on => :create, :message => _("El formato de la fecha no es correcto."), :allow_blank => true
  validate :fechas_peticion_prorroga

  before_validation :copiar_datos_convenio, :on => :create
  before_save :crea_libro_financiador
  after_create :copiar_mapeo_partidas_financiador, :copiar_relaciones_convenio
  after_create :asignar_grupos, :asignar_estado_inicial, :asignar_datos_dinamicos
  after_save :actualiza_espacio, :cambiar_monedas, :asignar_otras_financiaciones_presupuesto
  after_update :modificar_datos_pacs
  after_update :modificar_indicadores_generales_programa, if: :programa_marco_id_changed?
  after_destroy :limpia_gastos
  #after_destroy :borrar_espacio

  # Esto funciona, pero lo dejo comentado por no usarse aun
  #scope :sin_estado, includes(:estado).where( :estado => { :proyecto_id => nil } )

  def convenio?
    return self.attributes["convenio_accion"] ? true : false
  end

  # Devuelve el listado de cuentas contables mapeadas (plugin contabilidad)
  def cuentas_contables
    cuenta_contable.collect{|cc| "#{cc.codigo} (#{cc.delegacion.nombre})"}.join(", ")
  end

  # Devuelve los posibles paises de gasto
  def pais_gasto
    (pais + [ gestor.pais ]).uniq
  end

  # Devuelve el nombre (esto es necesario para hacer comunes los helpers en el listado de subcuentas)
  def codigo_nombre
    return self.nombre
  end

  def periodo_justificacion
    periodo.where(:tipo_periodo_id => [1,2]).order("fecha_inicio")
  end

  # Devuelve el siguiente pac en fechas
  def pac_siguiente
    siguiente = nil
    primera_fecha = self.fecha_de_inicio if self.convenio
    self.convenio.pacs.each do |pac|
      unless pac.etapa.empty?
        fecha_inicio_pac = pac.etapa.sort{ |a,b| a.fecha_inicio <=> b.fecha_inicio }.first.fecha_inicio
        if fecha_inicio_pac > primera_fecha
          siguiente = pac
          primera_fecha = fecha_inicio_pac
        end
      end
    end if self.convenio && primera_fecha
    return siguiente
  end

  # Devuelve el pac anterior en fechas
  def pac_anterior
    anterior = nil
    ultima_fecha = self.convenio.fecha_de_inicio if self.convenio
    self.convenio.pacs.each do |pac|
      unless pac.etapa.empty? || pac == self
        fecha_inicio_pac = pac.etapa.sort{ |a,b| a.fecha_inicio <=> b.fecha_inicio }.first.fecha_inicio 
        if fecha_inicio_pac < self.fecha_de_inicio && fecha_inicio_pac >= ultima_fecha
          anterior = pac
          ultima_fecha = fecha_inicio_pac
        end
      end
    end if self.convenio && ultima_fecha && self.fecha_de_inicio
    return anterior
  end

  # Devuelve la fecha de inicio y de fin
  # (inicio de la etapa mas temprana y fin de la etapa mas tardia)
  def fecha_de_inicio
    etapa.reorder(:fecha_inicio).first.fecha_inicio unless etapa.empty?
  end
  def fecha_de_fin
    etapa.reorder(:fecha_fin).last.fecha_fin unless etapa.empty?
  end

  # Devuelve la fecha de inicio y fin de actividades
  # teniendo en cuenta las etapas y las prorrogas de ejecucion
  def fecha_inicio_actividades
    fecha_de_inicio
  end
  def fecha_fin_actividades
    fecha = fecha_de_fin
    prorroga = periodo.where(periodo_cerrado: true).
                       joins(:tipo_periodo).
                       where("tipo_periodo.grupo_tipo_periodo" => "prorroga").
                       reorder(:fecha_fin).last
    (fecha && prorroga && prorroga.fecha_fin > fecha) ? prorroga.fecha_fin : fecha
  end

  # Devuelve la fecha de inicio y de fin de la justificacion
  # teniendo en cuenta los periodos de justificacion y las prorrogas
  def fecha_inicio_justificacion
    justificacion = periodo.where(periodo_cerrado: true).
                            joins(:tipo_periodo).
                            where("tipo_periodo.grupo_tipo_periodo" => ["final", "prorroga_justificacion"]).
                            reorder(:fecha_inicio).first
    justificacion.fecha_inicio if justificacion
  end
  def fecha_fin_justificacion
    justificacion = periodo.where(periodo_cerrado: true).
                            joins(:tipo_periodo).
                            where("tipo_periodo.grupo_tipo_periodo" => ["final", "prorroga_justificacion"]).
                            reorder(:fecha_fin).last
    justificacion.fecha_fin if justificacion
  end

  # Devuelve el numero de meses (fecha_de_fin - fecha_de_inicio) que tiene el proyecto (incluyendo mes no completo)
  def duracion_meses
    f_inicio = self.fecha_de_inicio
    f_fin = self.fecha_de_fin
    return f_inicio && f_fin ? (((f_fin.month) - f_inicio.month) + (12 * (f_fin.year - f_inicio.year)) + 1) : 0
  end

	# Devuelve el rol de un usuario en el proyecto o false si no esta en el
  def usuario_autorizado? user=nil
    # Aqui hacemos un order antes del find para que tenga preferencia la asignacion directa antes que la de grupo
    obj = usuario_x_proyecto.order(:grupo_usuario_id).find_by_usuario_id(user.id) if user && user.class.name == "Usuario"
    return obj ? obj.rol : false 
  end

  # Devuelve si el usuario esta asignado con un rol de privilegios especiales
  def usuario_admin? user=nil
    return user.privilegios_especiales?(self) if user.class.name == "Usuario"
  end

  # Devuelve los agentes para los que el usuario esta autorizado a ver la informacion economica
  def implementadores_autorizados user=nil
    if user && user.class.name == "Usuario" && ocultar_gastos_otras_delegaciones
      implementador.joins("LEFT JOIN usuario_x_agente ON usuario_x_agente.agente_id = agente.id").
                    where("usuario_x_agente.usuario_id = ? OR socia_local IS TRUE", user.id)
    else
      implementador
    end
  end
  
  # Devuelve los usuarios_x_ vinculados directamente (no a traves de grupo)
  def usuario_x_vinculado
    return usuario_x_proyecto.where(:grupo_usuario_id => nil)
  end

  # Si es un pac, copia los datos basicos del convenio antes de guardarse
  def copiar_datos_convenio
    if convenio_id
      self.convocatoria_id = self.convenio.convocatoria_id
      self.moneda_id = self.convenio.moneda_id
      self.moneda_intermedia_id = self.convenio.moneda_intermedia_id
      self.libro_id = self.convenio.libro_id
      self.gestor_id = self.convenio.gestor_id
    end
  end

  # Para los nuevos proyectos, genera el libro del financiador si no existe antes de guardar
  def crea_libro_financiador
    if self.libro_id == -1
      nombre_libro_inicial = self.nombre + "-" + self.agente.nombre + "-" + self.moneda_principal.abreviatura
      incremento = 0 
      nombre_libro = nombre_libro_inicial
      while Libro.find_by_nombre nombre_libro
        incremento += 1
        nombre_libro = nombre_libro_inicial + "-" + incremento.to_s
      end
      milibro = Libro.create(:nombre => nombre_libro, :descripcion => nombre_libro, :tipo => "banco", :moneda_id => self.moneda_id, :agente_id => self.gestor.id, :pais_id => self.agente.pais_id)
      self.libro_id = milibro.id
    end
  end

  # Para los nuevos proyectos (que no sean convenios), copiamos los mapeos de partidas definidos
  def copiar_mapeo_partidas_financiador
    # Recorre todas las partidas
    PartidaFinanciacion.find_all_by_agente_id(self.agente.id).each do |pf|
      # Copia la partida y modifica sus datos
      mipf = pf.dup
      mipf.proyecto_id = self.id
      mipf.agente_id = nil
      # Si la partida tiene madre, averiguamos cual es en el proyecto
      mipf.partida_financiacion_id = nil
      if pf_madre = pf.partida_financiacion_madre
        mipf_madre = PartidaFinanciacion.where(:proyecto_id => self.id, :codigo => pf_madre.codigo).first
        mipf.partida_financiacion_id = mipf_madre.id if mipf_madre
      end
      mipf.save
      # Copia el mapeo de partidas
      pf.partida_x_partida_financiacion.each { |pxpf| mipf.partida_x_partida_financiacion.create(:partida_id => pxpf.partida_id) } 
    end unless convenio_id
  end

  # Si es un pac, copia las relaciones del convenio
  def copiar_relaciones_convenio
    if convenio_id
      # Copia los usuarios asignados y sus roles
      self.convenio.usuario_x_proyecto.each { |uxp| self.usuario_x_proyecto.create(:usuario_id => uxp.usuario_id, :rol_id => uxp.rol_id) }
      # Copia los elementos del menu de relaciones
      self.convenio.proyecto_x_pais.each { |pxp| self.proyecto_x_pais.create(:pais_id => pxp.pais_id) }
      self.convenio.proyecto_x_moneda.each { |mxp| self.proyecto_x_moneda.find_or_create_by_moneda_id(mxp.moneda_id) }
      self.convenio.proyecto_x_financiador.each { |pxf| self.proyecto_x_financiador.find_or_create_by_agente_id(pxf.agente_id) }
      self.convenio.proyecto_x_implementador.each { |pxi| self.proyecto_x_implementador.find_or_create_by_agente_id(pxi.agente_id) }
      self.convenio.libro_x_proyecto.each { |lxp| self.libro_x_proyecto.find_or_create_by_libro_id(lxp.libro_id) }
      ProyectoXSectorPoblacion.all(:conditions => {:proyecto_id => self.convenio_id}).each do |pxs|
        ProyectoXSectorPoblacion.create(:proyecto_id => self.id, :sector_poblacion_id => pxs.sector_poblacion_id)
      end
      ProyectoXAreaActuacion.all(:conditions => {:proyecto_id => self.convenio_id}).each do |pxa|
        ProyectoXAreaActuacion.create(:proyecto_id => self.id, :area_actuacion_id => pxa.area_actuacion_id)
      end
      ProyectoXSectorIntervencion.all(:conditions => {:proyecto_id => self.convenio_id}).each do |pxs|
        ProyectoXSectorIntervencion.create(:proyecto_id => self.id, :sector_intervencion_id => pxs.sector_intervencion_id)
      end

      # Copia las partidas y sus relaciones
      self.convenio.partida_financiacion.each do |pf|
        #mipf = self.partida_financiacion.create(pf.attributes)
        mipf = pf.dup
        mipf.proyecto_id = self.id
        # Si la partida tiene madre, averiguamos cual es en el proyecto
        mipf.partida_financiacion_id = nil
        if pf_madre = pf.partida_financiacion_madre
          mipf_madre = PartidaFinanciacion.where(:proyecto_id => self.id, :codigo => pf_madre.codigo).first
          mipf.partida_financiacion_id = mipf_madre.id if mipf_madre
        end
        mipf.save
        pf.partida_x_partida_financiacion.each { |pxpf| PartidaXPartidaFinanciacion.create(:partida_financiacion_id => mipf.id, :partida_id => pxpf.partida_id) }
      end

      # Copia las subpartidas y sus relaciones
      self.convenio.subpartida.each do |sp|
        misp = sp.dup
        misp.proyecto_id = self.id
        misp.save
      end

      # Copia los objetivos especificos, general, resultados y actividades (junto a las hipotesis, fuentes e indicadores)
      self.convenio.objetivo_general.crear_asociacion_pacs if self.convenio.objetivo_general
      self.convenio.objetivo_especifico.each do |obj|
        obj.crear_asociacion_pacs
        obj.fuente_verificacion.each{|fv| fv.crear_asociacion_pacs}
        obj.indicador.each{|ind| ind.crear_asociacion_pacs}
        obj.hipotesis.each{|hip| hip.crear_asociacion_pacs}
      end
      self.convenio.resultado.each do |obj|
        obj.crear_asociacion_pacs
        obj.fuente_verificacion.each{|fv| fv.crear_asociacion_pacs}
        obj.indicador.each{|ind| ind.crear_asociacion_pacs}
        obj.hipotesis.each{|hip| hip.crear_asociacion_pacs}
      end
      self.convenio.actividad.each do |obj|
        obj.crear_asociacion_pacs
      end
    end
  end

  # Asigna los grupos automaticos con el rol indicado
  def asignar_grupos
    # Busca los grupos definidos como de asignacion automatica y los incluye en el proyecto
    GrupoUsuario.where("asignar_proyecto_rol_id IS NOT NULL").each do |grupo_automatico|
      GrupoUsuarioXProyecto.find_or_create_by_grupo_usuario_id_and_proyecto_id_and_rol_id(grupo_automatico.id,self.id,grupo_automatico.asignar_proyecto_rol_id)
    end
  end

  # Asigna el estado inicial de un proyecto recien creado
  def asignar_estado_inicial
    estado_inicial = DefinicionEstado.find_by_primer_estado(true)
    if estado_inicial && self.estado.empty?
      user = UserInfo.current_user
      user_id = user ? user.id : nil
      Estado.create definicion_estado_id: estado_inicial.id,
                    proyecto_id: self.id,
                    usuario_id: user_id,
                    estado_actual: true,
                    fecha_inicio: Date.today
    end
  end

  # Asigna los datos dinamicos que esten definidos como automaticos
  def asignar_datos_dinamicos
    DefinicionDato.where(asignar_proyecto: true).each do |definicion_dato|
      DatoTexto.find_or_create_by_proyecto_id_and_definicion_dato_id(self.id, definicion_dato.id)
    end
  end

  # Si es un convenio, copia los datos a sus pacs despues de una modificacion
  def modificar_datos_pacs
    self.pacs.each do |pac|
      pac.convocatoria_id = self.convocatoria_id
      pac.moneda_id = self.moneda_id
      pac.moneda_intermedia_id = self.moneda_intermedia_id
      pac.libro_id = self.libro_id
      pac.identificador_financiador = self.identificador_financiador
      pac.save      
    end if self.convenio?
  end

  # Cambia los indicadores generales segun el cambio de programa
  def modificar_indicadores_generales_programa
    # Averigua los indicadores del programa marco anterior
    indicadores_antiguos = IndicadorGeneralXProgramaMarco.where(programa_marco_id: programa_marco_id_was).collect{|ind| ind.indicador_general_id}
    indicadores_nuevos = IndicadorGeneralXProgramaMarco.where(programa_marco_id: programa_marco_id).collect{|ind| ind.indicador_general_id}
    # Indicadores del nuevo programa marco (a asignar)
    indicadores_nuevos.each do |ind_id|
      indicador_general_x_proyecto.find_or_create_by_indicador_general_id(ind_id)
    end
    # Indicadores del viejo programa marco (a eliminar si no hay datos de seguimiento)
    IndicadorGeneralXProyecto.destroy_all(proyecto_id: self.id, indicador_general_id: (indicadores_antiguos - indicadores_nuevos))
  end

  def actualiza_espacio
    espacio_padre = Espacio.find_by_nombre("Proyectos") unless self.convenio
    espacio_padre = Espacio.find_by_nombre(self.convenio.nombre) if self.convenio
    if espacio_padre && self.nombre_changed?
      if espacio
        espacio.update_attributes nombre: nombre, espacio_padre_id: espacio_padre.id
      else
        espacio = Espacio.create nombre: nombre, proyecto_id: self.id,
                                 espacio_padre_id: espacio_padre.id,
                                 descripcion: _("Espacio raíz del proyecto") + ": " + nombre
        #puts "-----------> ERROR: " + espacio.errors.inspect unless espacio.errors.empty?
      end
      espacio.errors.each {|e,m|  errors.add "Espacio", m}
      # Actualiza los espacios automaticos
      if espacio && espacio.errors.empty? 
        for esp in Espacio.find_all_by_definicion_espacio_proyecto_and_espacio_padre_id(true,nil)
          ne = Espacio.find_or_create_by_nombre_and_espacio_padre_id_and_definicion_espacio_proyecto_id(esp.nombre,espacio.id,esp.id)
          ne.errors.each {|e,m|  errors.add "", m}
        end
      end
    else
      logger.info "ERROR: No existe el espacio padre para el agente " + nombre if espacio_padre.nil?
    end
  end

  #def borrar_espacio
  #  for un_espacio in Espacio.find_all_by_definicion_espacio_proyecto(true)
  #    esp = Espacio.find_by_espacio_padre_id_and_definicion_espacio_proyecto_id(espacio.id, un_espacio.id)
  #    esp.destroy if esp
  #    esp.errors.each {|e,m|  errors.add "", m} if esp
  #  end
  #  espacio.destroy
  #end

  def asignar_otras_financiaciones_presupuesto
    if GorConfig.getValue(:AUTO_ASIGN_SYSTEM_AGENTS) == "TRUE"
      Agente.where(:sistema => true).each do |agt|
        ProyectoXFinanciador.find_or_create_by_agente_id_and_proyecto_id(agt.id, id)
      end
    end
  end

  def dato_dinamico id , tipo 
    eval( "Dato" + tipo ).find(id) unless id == 0
    eval( "Dato" + tipo ).new if id == 0 
  end

  def datos_dinamicos pestana
    dato_texto.joins(:definicion_dato).where("definicion_dato.grupo_dato_dinamico_id" => pestana.id).order("definicion_dato.rango") if pestana
  end

  def nombre_mayusculas
    self.nombre = self.nombre.upcase
  end

  # Validación de que las fechasd de petición de prorroga son correctas.
  def fechas_peticion_prorroga
    if fecha_limite_peticion_prorroga and fecha_inicio_aviso_peticion_prorroga
      if fecha_limite_peticion_prorroga and !fecha_inicio_aviso_peticion_prorroga
        errors.add("fecha_inicio_aviso_peticion_prorroga".  _("Fecha limite de petición de prorroga necesita de Fecha inicio aviso de petición de prorroga."))
      elsif !fecha_limite_peticion_prorroga and fecha_inicio_aviso_peticion_prorroga
        errors.add("fecha_limite_peticion_prorroga", _("Fecha inicio de aviso de petición de prorroga necesita Fecha limite de petición de prorroga."))
      elsif fecha_limite_peticion_prorroga < fecha_inicio_aviso_peticion_prorroga 
        errors.add("fecha_limite_peticion_prorroga", _("Fecha inicio de aviso de petición de prorroga debe ser menor que la Fecha limite de petición de prorroga."))
      end
    end
  end
  
  # Devuelve si nos encontramos en periodo de peticion de prorroga es decir si estamos entre las fechas definidas para tal fin
  def momento_peticion_prorroga
    hoy = Date.today
    if fecha_inicio_aviso_peticion_prorroga && fecha_limite_peticion_prorroga &&
       hoy > fecha_inicio_aviso_peticion_prorroga && hoy < fecha_limite_peticion_prorroga
      true 
    else
      false
    end  
  end
  def momento_peticion_prorroga_justificacion
    hoy = Date.today
    if fecha_inicio_aviso_peticion_prorroga_justificacion && fecha_limite_peticion_prorroga_justificacion &&
       hoy > fecha_inicio_aviso_peticion_prorroga_justificacion && hoy < fecha_limite_peticion_prorroga_justificacion
      true 
    else
      false
    end  
  end

  def estado_actual
    (estado.select { |a|  a.estado_actual }).first
  end

  # Obtiene el conjunto de partidas de sistema mapeadas en el proyecto
  # Lo quitamos de aqui para meterlo en un has_many
  #def partidas_mapeadas
  #  Partida.all(:order => "partida_financiacion.codigo,partida.codigo", :include => ["partida_financiacion"], :conditions => {"partida_financiacion.proyecto_id" => self.id})
  #end

  def partidas_mapeadas_financiador
    partidas_mapeadas.collect{|p| partida_financiacion.includes("partida_x_partida_financiacion").where("partida_x_partida_financiacion.partida_id" => p.id).first }
  end

  # Obtiene los codigos de actividades y de resultados y oe para exportacion/importacion
  def codigos_oe_resultados_y_actividades
    actividad.collect{|a| a.codigo} + resultado.collect{|r| "RE#" + r.codigo} + objetivo_especifico.collect{|o| "OE#" + o.codigo} + ["###"]
  end

  # Obtiene los nombres de actividades y de resultados y oe para exportacion/importacion
  def nombres_oe_resultados_y_actividades
    actividad.collect{|a| a.descripcion} + resultado.collect{|r| "RE: " + r.descripcion} + objetivo_especifico.collect{|o| "OE: " + o.descripcion} + [_("Todas las actividades")]
  end

  # Devuelve el presupuesto total formulado, aplicando tasas de cambio, según los filtros indicados (implementador, financiador y partida)
  def presupuesto_total_con_tc hash={}
    condiciones = {}
    condiciones[:agente_id] = hash[:implementador] if hash[:implementador]
    condiciones[:partida_id] = hash[:partida] if hash[:partida]
    condiciones["presupuesto_x_agente.agente_id"] = hash[:financiador] if hash[:financiador]
    calculo = hash[:financiador] ? "presupuesto_x_agente.importe * tasa_cambio" : "importe * tasa_cambio"
    incluidas = [ "tasa_cambio" ]
    incluidas.push("presupuesto_x_agente") if hash[:financiador]
    return presupuesto.includes(incluidas).where("tasa_cambio_id = tasa_cambio.id").where(condiciones).sum(calculo).to_f
  end

  # Devuelve el presupuesto total formulado agrupado por partidas del proyecto segun los filtros indicados (financiador)
  def presupuesto_total_x_partidas_proyecto hash={}
    resultado = [] 
    #par = VPresupuesto.partida_proyecto_financiador_agrupado self.id, "todas", "todas", "1", (hash[:financiador]||self.agente), 0
    par = VPresupuesto.sum_partida_proyecto(proyecto: self.id, agente: (hash[:financiador]||self.agente))
    par.each do |lp|
      lp_partida = partida_financiacion.find_by_id lp.fila_id
      importe = ((lp.importe * 100).to_i.to_f)/100
      resultado.push({ :partida_id => lp_partida.id, :nombre => lp_partida.nombre, :codigo => lp_partida.codigo, :importe => importe }) if lp_partida
    end
    return resultado 
  end

  # Devuelve el gasto total (aplicando tasas de cambio) segun los filtros indicados (fecha_fin, moneda, implementador, financiador, actividad, partida, pais)
  def gasto_total_con_tc hash={}
    joins = [ :gasto_x_proyecto ]
    condiciones = { "gasto_x_proyecto.proyecto_id" => id } unless hash[:pacs]
    condiciones = { "gasto_x_proyecto.proyecto_id" => self.pacs.where(:id => hash[:pacs]).collect{|p| p.id} } if hash[:pacs]

    condiciones["gasto.fecha"] = self.fecha_de_inicio..hash[:fecha_fin] if hash[:fecha_fin]
    condiciones["gasto.moneda_id"] = hash[:moneda] if hash[:moneda]
    condiciones["gasto.agente_id"] = hash[:implementador] if hash[:implementador]
    joins.push(:gasto_x_agente) if hash[:financiador]
    condiciones["gasto_x_agente.agente_id"] = hash[:financiador] if hash[:financiador]
    joins.push(:gasto_x_actividad) if hash[:actividad]
    condiciones["gasto_x_actividad.actividad_id"] = hash[:actividad] if hash[:actividad]
    condiciones["gasto.partida_id"] = hash[:partida] if hash[:partida]
    condiciones["gasto.pais_id"] = hash[:pais] if hash[:pais]

    gastos = Gasto.joins(joins).includes([:gasto_x_proyecto,:partida,:agente]).where(condiciones)
    suma_total = gastos.joins(:gasto_x_proyecto => :tasa_cambio_proyecto).sum("gasto_x_proyecto.importe*tasa_cambio") unless hash[:financiador]
    suma_total = gastos.joins(:gasto_x_proyecto => :tasa_cambio_proyecto).sum("gasto_x_agente.importe*tasa_cambio") if hash[:financiador]
    return suma_total
  end

  # Devuelve el gasto total (aplicando tasas de cambio) por partidas del proyecto segun los filtros indicados (fecha_fin, financiador)
  def gasto_total_x_partidas_proyecto hash={}
    resultado = []

    par = VGasto.agrupa_sum_partida_proyecto( proyecto: id, moneda: "todas", rol_agente: "financiador", agente: hash[:financiador]||agente, fecha_inicio: hash[:fecha_inicio]||fecha_de_inicio, fecha_fin: hash[:fecha_fin]||fecha_de_fin )
    par.each do |lp|
      lp_partida = partida_financiacion.find_by_id lp["fila_id"]
      importe = ((lp["importe"] * 100).to_i.to_f)/100 if lp["importe"]
      resultado.push({ :partida_id => lp_partida.id, :nombre => lp_partida.nombre, :codigo => lp_partida.codigo, :importe => importe }) if lp_partida && lp["importe"]
    end
    return resultado
  end

  # Devuelve los intereses totales con TC aplicada
  def suma_intereses_con_tc hash={}
    total = 0
    # Como podriamos tener que calcular la TC para cada moneda/pais segun los gastos (y no hay relacion directa), solo podemos agrupar por cuentas
    condiciones = {:tipo => "intereses"}
    condiciones["transferencia_x_agente.agente_id"] = hash[:financiador] if hash[:financiador]
    condiciones["fecha_recibido"] = self.fecha_de_inicio..hash[:fecha_fin] if hash[:fecha_fin]
    totales_por_cuenta = transferencia.includes("transferencia_x_agente").where(condiciones).group("libro_destino_id").sum("transferencia_x_agente.importe")
    # Ahora recorremos los totales por cuenta para sumar segun las TC del periodo de la fecha enviada
    totales_por_cuenta.each do |t|
      libro = Libro.find_by_id t[0]
      # Nos inventamos un gasto de esa fecha para averiguar cual seria su TC
      tcg = TasaCambio.tasa_cambio_para_gasto(Gasto.new(:moneda_id => libro.moneda_id, :pais_id => libro.pais_id, :fecha => (hash[:fecha_fin]||self.fecha_de_fin)), self) if libro
      total += t[1] * tcg.tasa_cambio if tcg
    end
    return total
  end

  # Devuelve un array de totales de importes de contratos segun estados de los contratos
  # Se le puede pasar un hash de condiciones
  def totales_contratos condiciones={}
    totales = []

    todos = contrato.joins(:workflow_contrato).where(condiciones)
    mon_abr = moneda_principal.abreviatura

    # Total presupuestado
    contratos = todos
    # Usamos fecha_fin del periodo de contrato porque se asume que ahi es cuando se produce el gasto del hito
    importe_presupuestado = contratos.joins(:periodo_contrato, proyecto: [etapa: :tasa_cambio]).
                                      where("tasa_cambio.moneda_id = contrato.moneda_id AND objeto = 'presupuesto'").
                                      where("etapa.fecha_inicio <= periodo_contrato.fecha_fin AND etapa.fecha_fin >= periodo_contrato.fecha_fin").
                                      sum("periodo_contrato.importe * tasa_cambio.tasa_cambio")
    totales.push( nombre: "presupuesto_total", etiqueta: _("Total Presupuestado"), importe: importe_presupuestado.to_f, moneda: mon_abr)

    # Importe comprometido (presupuestos aprobados)
    contratos = todos.where("workflow_contrato.aprobado" => true)
    importe_comprometido = contratos.joins(:periodo_contrato, proyecto: [etapa: :tasa_cambio]).
                                     where("tasa_cambio.moneda_id = contrato.moneda_id AND objeto = 'presupuesto'").
                                      where("etapa.fecha_inicio <= periodo_contrato.fecha_fin AND etapa.fecha_fin >= periodo_contrato.fecha_fin").
                                     sum("periodo_contrato.importe * tasa_cambio.tasa_cambio")
    totales.push( nombre: "presupuesto_aprobado", etiqueta: _("Comprometido"), importe: importe_comprometido.to_f, moneda: mon_abr)

    # Importe ejecucion (gastos de contratos aprobados en ejecucion)
    gastos = gasto.joins(gasto_x_contrato: {contrato: :workflow_contrato}).
                   where(condiciones).where("workflow_contrato.aprobado" => true)
    importe_ejecutado = gastos.joins(:gasto_x_proyecto => :tasa_cambio_proyecto).
                   where("gasto_x_proyecto.proyecto_id" => self.id).
                   sum("gasto_x_proyecto.importe*tasa_cambio")
    totales.push( nombre: "gasto_ejecutado", etiqueta: _("Total Ejecutado"), importe: importe_ejecutado.to_f, moneda: mon_abr)

    # Importe pendiente (presupuesto - gastos, de contratos aprobados en ejecucion)
    gastos = gasto.joins(gasto_x_contrato: {contrato: :workflow_contrato}).
                   where(condiciones).where("workflow_contrato.aprobado" => true, "workflow_contrato.cerrado" => false)
    contratos = todos.where("workflow_contrato.aprobado" => true, "workflow_contrato.cerrado" => false)
    importe_ejecutado = gastos.joins(:gasto_x_proyecto => :tasa_cambio_proyecto).
                               where("gasto_x_proyecto.proyecto_id" => self.id).
                               sum("gasto_x_proyecto.importe*tasa_cambio")
    importe_ppto_ejec = contratos.joins(:periodo_contrato, proyecto: [etapa: :tasa_cambio]).
                                  where("tasa_cambio.moneda_id = contrato.moneda_id AND objeto = 'presupuesto'").
                                  where("etapa.fecha_inicio <= periodo_contrato.fecha_fin AND etapa.fecha_fin >= periodo_contrato.fecha_fin").
                                  sum("periodo_contrato.importe * tasa_cambio.tasa_cambio")
    totales.push( nombre: "pendiente_ejecucion", etiqueta: _("Pendiente Ejecución"), importe: (importe_ppto_ejec.to_f - importe_ejecutado.to_f), moneda: mon_abr)

    # Importe disponible (total presupuestado en el proyecto - total presupuestado aprobado)
    importe_disponible = presupuesto_total_con_tc({implementador: implementador.where(socia_local: false)}).to_f - importe_comprometido.to_f
    totales.push( nombre: "disponible", etiqueta: _("Disponible"), importe: importe_disponible, moneda: mon_abr)

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

  #A extinguir en alguna refactorizacion.
  def presupuesto_total_sin_financiador
    return self.presupuesto_total_con_tc
  end

  #A extinguir en alguna refactorizacion.
  def presupuesto_total_con_financiador financiador
    return self.presupuesto_total_con_tc :financiador => financiador
  end

  # Devuelve el presupuesto total del proyecto en la moneda base o el de la moneda que se especifique. Si no se especifica moneda, aplica TC
  # A extinguir en alguna refactorizacion teniendo en cuenta el calculo de TC
  def presupuesto_total mon=nil, financ=nil
    total = 0.0
    financ = nil unless financ.class.name == "Agente"
    condiciones = {} 
    #fecha_inicio = self.etapa.sort{ |a,b| a.fecha_inicio <=> b.fecha_inicio }.first.fecha_inicio if fecha_fin
    #condiciones = { :fecha => fecha_inicio..fecha_fin } if fecha_fin && fecha_fin.class.name == "Date"
    condiciones["presupuesto_x_agente.agente_id"] = financ.id if financ
    condiciones["presupuesto.moneda_id"] = mon.id if mon and mon.class.name=="Moneda"
    self.presupuesto.all(:include => "presupuesto_x_agente", :conditions => condiciones).each do |pre|
      importe = financ ? pre.presupuesto_x_agente.first.importe : pre.importe
      total += importe if mon
      total += (importe * pre.tasa_cambio).round(2) unless mon
    end
    return total
  end

  # A extinguir en alguna refactorizacion
  def gasto_total_sin_financiador
    # Si es un convenio, devuelve la suma de gasto de los pacs
    proyectos = self.convenio_accion ? self.pacs : [self]
    total = 0
    proyectos.each do |p|
      resultado = Gasto.find_by_sql "select sum(gasto_x_proyecto.importe * tasa_cambio) as total from gasto left join gasto_x_proyecto on gasto.id = gasto_x_proyecto.gasto_id left join tasa_cambio on tasa_cambio.id = gasto_x_proyecto.tasa_cambio_id where  gasto_x_proyecto.proyecto_id = #{p.id}"
      total += resultado.first.total.to_f
    end
    return total 
  end

  # A extinguir en alguna refactorizacion
  def gasto_total_con_financiador financiador
    # Si es un convenio, devuelve la suma de gasto de los pacs
    proyectos = self.convenio_accion ? self.pacs : [self]
    total = 0
    proyectos.each do |p|
      resultado = Gasto.find_by_sql "  select sum(gasto_x_agente.importe * tasa_cambio) as total from gasto left join gasto_x_proyecto on gasto.id = gasto_x_proyecto.gasto_id left join tasa_cambio on tasa_cambio.id = gasto_x_proyecto.tasa_cambio_id left join gasto_x_agente on gasto_x_agente.gasto_id = gasto.id and gasto_x_agente.proyecto_id = gasto_x_proyecto.proyecto_id where  gasto_x_proyecto.proyecto_id = #{p.id} and gasto_x_agente.agente_id = #{financiador.id} and gasto_x_agente.proyecto_id = #{p.id} " 
      total += resultado.first.total.to_f
    end
    return total
  end

 # Devuelve el gasto total del proyecto en la indicada o la moneda base si no esta definida
 def gasto_total financ=nil, mon=nil, etap=nil, pai=nil
   total = 0.0
   financ = nil unless financ.class.name == "Agente"
   etap = nil unless etap.class.name == "Etapa"
   mon = nil unless mon.class.name == "Moneda"
   pai = nil unless pai.class.name == "Pais"
   condiciones = {}
   condiciones["gasto_x_agente.agente_id"] = financ.id if financ
   condiciones["gasto.fecha"] = etap.fecha_inicio..etap.fecha_fin if etap
   condiciones["gasto.moneda_id"] = mon.id if mon
   condiciones["gasto.pais_id"] = pai.id if pai
   # Recorremos todos los gastos
   self.gasto.all(:include => ["gasto_x_agente"], :conditions => condiciones).each do |gas|
     # Pillamos el gasto por financiador si se ha pedido eso (financ != nil)
     gxa = gas.gasto_x_agente.first if financ
     # Pillamos el gasto por proyecto (necesario tambien para la tasa de cambio)
     gxp = gas.gasto_x_proyecto.find_by_proyecto_id self.id
     # Escogemos el importe segun sea de financiador o completo del proyecto
     importe = gxa ? gxa.importe : gxp.importe

     # Si no hay moneda, le aplicamos la tasa de cambio
     total += (importe * gxp.tasa_cambio).round(2) if importe && gxp && mon.nil?
     # Si hay moneda, no convertimos el importe 
     total += importe if importe && mon
   end
   #puts "----------------> Nos piden el gasto para"
   #puts "                  PAIS: " + pai.nombre if pai
   #puts "                  MONEDA: " + mon.nombre if mon
   #puts "                  ETAPA: " + etap.nombre if etap
   #puts "                  FINANC: " + financ.nombre if financ
   #puts "                  " + total.to_s
   return total
 end

 # Devuelve el total de transferencias realizadas (para una o todas las monedas)
 def transferido_total mon, etap=nil, financ=nil, direccion="entrante", tipo=nil, pai=nil, evita_remanente=false
   total = 0.0
   pai = nil unless pai.class.name == "Pais"
   if mon && mon.class.name == "Moneda"

     incluye_tabla = "libro_origen" if direccion == "saliente"
     incluye_tabla = "libro_destino" if direccion == "entrante"
    
     # Filtros basicos de la transferencia... luego los complicaremos sobre los resultados
     #condiciones  = "moneda_id = " + mon.id.to_s 
     condiciones = "libro.moneda_id = " + mon.id.to_s
     condiciones += " AND transferencia.tipo = '" + tipo.to_s + "'" if tipo
     condiciones += " AND transferencia.tipo != 'remanente'" if tipo.nil? && evita_remanente
     condiciones += " AND transferencia_x_agente.agente_id = " + financ.id.to_s if financ.class.name == "Agente"
     if etap.class.name == "Etapa"
       condiciones += " AND " + (direccion == "saliente" ? "fecha_enviado" : "fecha_recibido") + " BETWEEN '" + etap.fecha_inicio.to_s + "' AND '" + etap.fecha_fin.to_s + "'" 
     end

     #logger.info "---------------------" 
     #logger.info "---------------------> Miramos sobre la moneda " + mon.abreviatura + " con las condiciones " + condiciones
     #logger.info "---------------------> Incluyendo la tabla: " + incluye_tabla
     #logger.info "---------------------> Pais: " + pai.nombre if pai
     #logger.info "---------------------> Direccion: " + direccion if direccion
     #logger.info "---------------------> Agente: " + financ.inspect if financ
     transf_filtradas = self.transferencia.all(:include => [incluye_tabla, 'transferencia_x_agente'], :conditions => condiciones)
     transf_filtradas.each do |trans|
       #logger.info "---------------------> " + trans.inspect
       # Contabiliza solo las que sean a distinta moneda o distinto pais a no ser que sea sin segunda cuenta 
       if (tipo && trans.tipo =~ /subvencion|reintegro|iva|intereses|adelanto|devolucion/) || (trans.libro_origen && trans.libro_destino && (trans.libro_origen.moneda_id != trans.libro_destino.moneda_id || trans.libro_origen.pais_id != trans.libro_destino.pais_id))
         # Contabiliza solo las transferencias del pais (o si no se pide por pais, todas)
         if pai == nil ||
		(direccion == "saliente" && trans.libro_origen && trans.libro_origen.pais == pai) ||
		(direccion == "entrante" && trans.libro_destino && trans.libro_destino.pais == pai)
           # Selecciona el importe total ...
           unless financ.class.name == "Agente"
             #logger.info "------> Miramos por el total"
             importe_tmp = (direccion == "saliente" ? trans.importe_enviado : trans.importe_cambiado)
           # ... o el del financiador (aqui hay que ajustar para que coja el mismo porcentaje en el caso de que sea entrante)
           else 
             #logger.info "------> Miramos por el agente"
             txf = trans.transferencia_x_agente.find_by_agente_id(financ.id)
            
             # Para salientes si existe transferencia_x_financiador para ese financiador 
             importe_tmp = txf.importe if direccion == "saliente" && txf
             #logger.info "------> Tenemos enviado: " + txf.importe.to_s if direccion == "saliente" && txf
            
             # Y para entrantes, si existe transferencia_x_financiador para ese financiador y la transferencia se ha recibido, calcula el porcentaje sobre el enviado o el recibido
             if direccion == "entrante" && trans.importe_cambiado && txf
               #logger.info "Tenemos Enviado: " + trans.importe_enviado.inspect + " Cambiado: " + trans.importe_cambiado.inspect + " Recibido: " + trans.importe_enviado.inspect + " y txf " + txf.inspect
               importe_tmp = trans.importe_cambiado * (txf.importe / (trans.importe_enviado || trans.importe_recibido))
             end
           end
           # Si se ha indicado la direccion, se contabilizan solo esas
           total += importe_tmp if importe_tmp
           #logger.info "    Total acumulado: " + total.inspect
         end
       end
     end if transf_filtradas
   end
   return total
 end

  # Devuelve el resumen de tesoreria para un financiador y una etapa dada. mon_base define si debemos expresar los remanentes en moneda base o en cada moneda local
  def tesoreria financ, etap, mon_base=true
    filas = []
    cabecera_fila = []
    paises = self.pais
    pais_subvencion = (self.libro_principal||self.agente).pais
    resto_paises = paises - [pais_subvencion]

    # Genera la cabecera de las columnas a mostrar...
    # ... base sin pais
    cabecera_col = [ {:pais_id => nil, :moneda_id => self.moneda_principal.id} ]
    # ... moneda principal por paises
    cabecera_col += paises.collect { |p| {:pais_id => p.id, :moneda_id => self.moneda_principal.id} unless p.moneda.find_by_id(self.moneda_id) }
    # ... divisa por paises
    cabecera_col += paises.collect { |p| {:pais_id => p.id, :moneda_id => self.moneda_intermedia.id} unless self.moneda_intermedia.nil? || p.moneda.find_by_id(self.moneda_intermedia_id) }
    # ... monedas locales por paises excluyendo el pais de la cuenta de subvencion (elmiminando el pais+moneda del financiador principal)
    paises.each { |p| cabecera_col += p.moneda.collect{|m| {:pais_id => p.id, :moneda_id => m.id} unless self.moneda_id == m.id && pais_subvencion.id == p.id } }
    #paises.each { |p| cabecera_col += p.moneda.collect{|m| {:pais_id => p.id, :moneda_id => m.id} } }
    # ... y limpia los nil que haya en el array
    cabecera_col.delete(nil)

    # Obtiene el saldo anterior del pac previo
    saldo_anterior = nil
    if self.pac_anterior
      # Esta no es una buena forma, porque para la tesoreria del pac4 se tiene que calcular la del anterior y quedaria pac3->pac2->pac1
      (prev_cab_col,prev_cab_fil,prev_filas) = self.pac_anterior.tesoreria(financ,etap,mon_base)
      saldo_anterior_euros = prev_filas[-1][0] 
      saldo_anterior = prev_filas[-4]
      cambio_anterior = prev_filas[-3]
    end

    # Transferencias de subvenciones (por agente y total) -> Habria problemas con financiaciones en otras monedas!!!
    principal_financia = self.transferido_total(self.moneda_principal, etap, financ, "entrante", "subvencion", nil)
    total_financia = self.transferido_total(self.moneda_principal, etap, nil, "entrante", "subvencion", nil)

    # Calcula el total saliente para el pais/moneda principal de la subvencion
    principal_enviado = self.transferido_total(self.moneda_principal, etap, financ, "saliente", nil, pais_subvencion, !mon_base)
    principal_enviado -= self.transferido_total(self.moneda_principal, etap, financ, "entrante", nil, pais_subvencion, !mon_base)

    # Dinero transferido a los paises (entrante y saliente) para moneda del proyecto e intermedia (evitando los paises que las tengan como local)
    # Esto genera las lineas "total divisa intermedia" y "total divisa recibida y cambiada"
    principal_entrante = paises.collect do |p|
      self.transferido_total(self.moneda_principal, etap, financ, "entrante", nil, p, !mon_base) unless p.moneda.find_by_id(self.moneda_id)
    end
    principal_saliente = paises.collect do |p|
      self.transferido_total(self.moneda_principal, etap, financ, "saliente", nil, p, !mon_base) unless p.moneda.find_by_id(self.moneda_id)
    end
    divisa_saliente = []
    divisa_saliente = paises.collect do |p|
      self.transferido_total(self.moneda_intermedia, etap, financ, "saliente", nil, p, !mon_base) unless p.moneda.find_by_id(self.moneda_intermedia_id)
    end if self.moneda_intermedia
    divisa_entrante = []
    divisa_entrante = paises.collect do |p|
      self.transferido_total(self.moneda_intermedia, etap, financ, "entrante", nil, p, !mon_base) unless p.moneda.find_by_id(self.moneda_intermedia_id)
    end if self.moneda_intermedia
    principal_saliente.delete(nil)
    principal_entrante.delete(nil)
    divisa_saliente.delete(nil)
    divisa_entrante.delete(nil)
    divisa_total_entrante = principal_entrante + divisa_entrante
    divisa_total_saliente = principal_saliente + divisa_saliente
   
    # Moneda local recibida
    locales_entrante = paises.inject([]) do |sum, p|
      # Cuando estamos en el pais principal, no consideramos la moneda principal como local
      monedas = p.moneda - (p == pais_subvencion ? [self.moneda_principal] : []) 
      sum + monedas.collect{|m| self.transferido_total(m, etap, financ, "entrante", nil, p, !mon_base)}
    end
    # Moneda local saliente
    locales_saliente = paises.inject([]) do |sum, p|
      # Cuando estamos en el pais principal, no consideramos la moneda principal como local
      monedas = p.moneda - (p == pais_subvencion ? [self.moneda_principal] : [])
      sum + monedas.collect{|m| self.transferido_total(m, etap, financ, "saliente", nil, p, !mon_base)}
    end


    # Intereses de la moneda principal en el pais de justificacion
    intereses_principal = self.transferido_total(self.moneda_principal, etap, financ, "entrante", "intereses", pais_subvencion)
    # Intereses a las cuentas en moneda principal como divisa en los paises
    intereses_principal_paises = paises.collect do |p|
      self.transferido_total(self.moneda_principal, etap, financ, "entrante", "intereses", p) unless p.moneda.find_by_id(self.moneda_id)
    end
    intereses_principal_paises.delete(nil)
    # Intereses totales de la moneda principal
    intereses = [ intereses_principal ] + intereses_principal_paises

    # Intereses para divisa
    intereses += paises.collect do |p|
      self.transferido_total(self.moneda_intermedia, etap, financ, "entrante", "intereses", p) unless p.moneda.find_by_id(self.moneda_intermedia_id)
    end if self.moneda_intermedia
    intereses.delete(nil)

    # Intereses para monedas locales
    paises.each do |p|
      # Cuando estamos en el pais principal, no consideramos la moneda principal como local
      monedas = p.moneda - (p == pais_subvencion ? [self.moneda_principal] : [])
      intereses += monedas.collect{|m| self.transferido_total(m, etap, financ, "entrante", "intereses", p) }
    end


    # Solo incluye IVA si existe alguna transferencia de ese tipo
    unless self.transferencia.find_by_tipo("iva")
      iva_recuperado = nil
    else
      # IVA recuperado de la moneda principal en el pais de justificacion
      iva_principal = self.transferido_total(self.moneda_principal, etap, financ, "entrante", "iva", pais_subvencion)
      # IVA recuperado en las cuentas en moneda principal como divisa en los paises
      iva_principal_paises = paises.collect do |p|
        self.transferido_total(self.moneda_principal, etap, financ, "entrante", "intereses", p) unless p.moneda.find_by_id(self.moneda_id)
      end
      iva_principal_paises.delete(nil)
      # IVA totales de la moneda principal
      iva_recuperado = [ iva_principal ] + iva_principal_paises

      # IVA recuperado para divisa
      iva_recuperado += paises.collect do |p|
        self.transferido_total(self.moneda_intermedia, etap, financ, "entrante", "iva", p) unless p.moneda.find_by_id(self.moneda_intermedia_id)
      end if self.moneda_intermedia
      iva_recuperado.delete(nil)

      # IVA para monedas locales
      paises.each do |p|
        # Cuando estamos en el pais principal, no consideramos la moneda principal como local
        monedas = p.moneda - (p == pais_subvencion ? [self.moneda_principal] : [])
        iva_recuperado += monedas.collect{|m| self.transferido_total(m, etap, financ, "entrante", "iva", p) }
      end
    end

    # Solo incluye Reintegro de Subvencion si existe alguna transferencia de ese tipo
    unless self.transferencia.find_by_tipo("reintegro")
      reintegro = nil
    else
      # Reintegro de la moneda principal en el pais de justificacion
      reintegro_principal = self.transferido_total(self.moneda_principal, etap, financ, "saliente", "reintegro", pais_subvencion)
      # IVA recuperado en las cuentas en moneda principal como divisa en los paises
      reintegro_principal_paises = paises.collect do |p|
        self.transferido_total(self.moneda_principal, etap, financ, "saliente", "reintegro", p) unless p.moneda.find_by_id(self.moneda_id)
      end
      reintegro_principal_paises.delete(nil)
      # Reintegros totales de la moneda principal
      reintegro = [ reintegro_principal ] + reintegro_principal_paises

      # Reintegro para divisa
      reintegro += paises.collect do |p|
        self.transferido_total(self.moneda_intermedia, etap, financ, "saliente", "reintegro", p) unless p.moneda.find_by_id(self.moneda_intermedia_id)
      end if self.moneda_intermedia
      reintegro.delete(nil)

      # Reintegro para monedas locales
      paises.each do |p|
        # Cuando estamos en el pais principal, no consideramos la moneda principal como local
        monedas = p.moneda - (p == pais_subvencion ? [self.moneda_principal] : [])
        reintegro += monedas.collect{|m| self.transferido_total(m, etap, financ, "saliente", "reintegro", p) }
      end
    end


    #  Fondos totales de la subvencion
    total_fondos = [  principal_financia - principal_enviado] +
                      divisa_total_entrante.zip(divisa_total_saliente).map {|a| a.inject(:-)} +
                      locales_entrante.zip(locales_saliente).map {|a| a.inject(:-)}
    # ... incluyendo remanentes
    total_fondos = total_fondos.zip(saldo_anterior).map {|a| a.inject(:+)} if saldo_anterior && !mon_base
    total_fondos[0] += saldo_anterior_euros if saldo_anterior && mon_base
    # ... e incluyendo intereses, iva y reintegros
    total_fondos = total_fondos.zip(intereses).map {|a| a.inject(:+)}
    total_fondos = total_fondos.zip(iva_recuperado).map {|a| a.inject(:+)} if iva_recuperado
    total_fondos = total_fondos.zip(reintegro).map {|a| a.inject(:-)} if reintegro


    #
    # Gastos
    #

    #  gastos del pais de subvencion en moneda principal
    gastos_principal = self.gasto_total(financ, self.moneda_principal, etap, pais_subvencion)

    # Gastos de cuentas en moneda principal como divisa en los paises
    gastos_principal_paises = paises.collect do |p|
      self.gasto_total(financ, self.moneda_principal, etap, p) unless p.moneda.find_by_id(self.moneda_id)
    end
    gastos_principal_paises.delete(nil)
    # Gastos totales de la moneda principal
    gastos = [ gastos_principal ] + gastos_principal_paises

    # Gastos hechos en divisa
    gastos += paises.collect do |p|
      self.gasto_total(financ, self.moneda_intermedia, etap, p) unless p.moneda.find_by_id(self.moneda_intermedia_id)
    end if self.moneda_intermedia
    gastos.delete(nil)

    # Gastos en monedas locales
    paises.each do |p|
      # Cuando estamos en el pais principal, no consideramos la moneda principal como local
      monedas = p.moneda - (p == pais_subvencion ? [self.moneda_principal] : [])
      gastos += monedas.collect{|m| self.gasto_total(financ, m, etap, p) }
    end

    # Saldos corrientes
    saldos = total_fondos.zip(gastos).map {|a| a.inject(:-)}

    # Tasas de Cambio
    # Hay que corregir la ultima fecha para que sea de TC y no de etapa 
    ultima_fecha = etap ? etap.fecha_fin : (self.etapa.empty? ? Date.new : self.etapa.last(:order => "fecha_fin").fecha_fin)

    #  tasa de cambio para moneda principal
    tasa_cambio = [ 1 ] + principal_saliente.collect{|a| 1}
    #  y de la divisa (si existe) por paises
    if self.moneda_intermedia_id
      tasa_cambio += paises.collect do |p|
        unless p.moneda.include?(self.moneda_intermedia)
          tcg = TasaCambio.tasa_cambio_para_gasto(Gasto.new(:moneda_id => self.moneda_intermedia_id, :pais_id => p.id, :fecha => ultima_fecha), self)
          tcg ? tcg.tasa_cambio : 0 
        end
      end
    end

    #  tasa de cambio por paises y monedas
    paises.each { |p| tasa_cambio += p.moneda.collect{|m|
      unless p == pais_subvencion && m == self.moneda_principal
        tcg = TasaCambio.tasa_cambio_para_gasto(Gasto.new(:moneda_id => m.id, :pais_id => p.id, :fecha => ultima_fecha), self)
        tcg ? tcg.tasa_cambio : 0
      end 
    } }
    tasa_cambio.delete(nil)

    # Totales
    saldos_convertidos = saldos.zip(tasa_cambio).map {|a| a.inject(:*)}
    total_euros = saldos_convertidos.inject(0){|sum, sc| sum + sc}

    # Construye la salida final
    if saldo_anterior
      cabecera_fila.push( _("(+) Saldos de periodos anteriores") )
      filas.push( [saldo_anterior_euros] ) if mon_base
      filas.push( saldo_anterior ) unless mon_base
    end
    cabecera_fila.push( _("(+) Subvención recibida ") + (financ ? financ.nombre : "") )
    filas.push( [ principal_financia] )
    cabecera_fila.push( _("(-) Total %{mon} transferidos")%{:mon =>  self.moneda_principal.nombre.pluralize} ) 
    filas.push( [ principal_enviado ] )
    cabecera_fila.push( _("(+) Total Divisa intermedia") )
    filas.push( [""] + divisa_total_entrante )
    cabecera_fila.push( _("(-) Total Divisa recibida y cambiada") )
    filas.push( [""] + divisa_total_saliente )
    cabecera_fila.push( _("(+) Total Moneda Local obtenida") )
    filas.push( [""] + divisa_total_saliente.collect{|a| ""} + locales_entrante )
    cabecera_fila.push( _("(-) Moneda Local recibida y cambiada") )
    filas.push( [""] + divisa_total_saliente.collect{|a| ""} + locales_saliente )
    cabecera_fila.push( _("(+) Total Intereses Generados") )
    filas.push( intereses )
    if iva_recuperado
      cabecera_fila.push( _("(+) Iva Recuperado") )
      filas.push( iva_recuperado )
    end
    if reintegro
      cabecera_fila.push( _("(-) Reintegro subvención") )
      filas.push( reintegro )
    end
    cabecera_fila.push( _("(I) TOTAL Fondos de la subvencion") )
    filas.push( total_fondos )
    cabecera_fila.push( _("(II) GASTOS aplicados (-)") )
    filas.push( gastos )
    cabecera_fila.push( _("(III) SALDOS CORRIENTES (I) - (II)") )
    filas.push( saldos )
    cabecera_fila.push( _("Tipo de cambio aplicable") )
    filas.push( tasa_cambio )
    cabecera_fila.push( _("(IV) SALDO") + " " + _("%{mon} EQUIVALENTES")%{:mon => self.moneda_principal.nombre.pluralize} )
    filas.push( saldos_convertidos )
    cabecera_fila.push( _("(V) TOTAL") + " " + self.moneda_principal.nombre.pluralize )
    filas.push( [total_euros] )

    return cabecera_col, cabecera_fila, filas 
  end

	# Aplica los remanentes segun el estado de tesoreria del PAC anterior
  def aplica_remanentes mon_base=true
    # Borra todos los remanentes existentes
    Transferencia.all(:conditions => {:remanente => true, :proyecto_id => self.id}).each {|rem| rem.destroy} if self.pac_anterior
    # Si hay un pac anterior recorre todas las cuentas
    self.libro.each do |l|
      # Si el libro es el principal del proyecto pone el total
      if self.libro_id == l.id
        (cab_col, cab_fila, filas) = self.pac_anterior.tesoreria(self.agente, nil)
        rem_importe = filas[-1][0]
      # Para el resto de los libros...  
      else
        # ... obtiene el arqueo de caja del libro (sobre el financiador principal)
        arqueo =  l.arqueo [ self.pac_anterior ], nil, nil, self.agente
        rem_importe = arqueo[:entrante] - arqueo[:saliente]
      end
      # Si el remanente es positivo, se incluye
      if (rem_importe) != 0.0
        gasto_falso = Gasto.new(:moneda_id => l.moneda_id, :fecha => self.pac_anterior.fecha_de_fin, :pais_id => l.pais_id)
        # Obtiene su ultima tasa de cambio
        tc = TasaCambio.tasa_cambio_para_gasto(gasto_falso, self.pac_anterior)
        tc_valor = tc ? tc.tasa_cambio : 0 
        # Genera una transferencia con el remanente (con new para incluir callbacks)
        t = Transferencia.new(	:proyecto_id => self.id, :remanente => true, :tipo => "remanente",
				:libro_origen_id => self.libro_id, :libro_destino_id => l.id,
				:fecha_recibido => self.fecha_de_inicio,
				:importe_recibido => rem_importe * tc_valor, :importe_cambiado => rem_importe, :tasa_cambio => tc_valor,
				:observaciones => _("Remanente") + " " + self.pac_anterior.nombre )
	# Si los libros no son los mismos, introduce los datos de enviado
        if self.libro_id != l.id
          t.importe_enviado = t.importe_recibido 
          t.fecha_enviado = self.fecha_de_inicio 
        end
        t.save
        # Y si todo esta bien guardado, el financiador principal
        txf = TransferenciaXAgente.create( :transferencia_id => t.id, :agente_id => self.agente.id, :importe => t.importe_recibido) if t.errors.empty?
      end
    end if self.pac_anterior
  end

  def presupuesto_cofinanciado_privado
  end

  # Todas las formas de pago disponibles
  def formas_de_pago
    Pago.formas_de_pago
  end

  # Cadena de texto con todos los nombres de financiadores
  def financiadores_nombre
    financiador_gasto.collect{|f| f.nombre}.join(", ")
  end

  # Cadena de texto con todos los nombres de otros financiadores (quitamos al principal)
  def otros_financiadores_nombre
    (financiador_gasto - [agente]).collect{|f| f.nombre}.join(", ")
  end

  # Cadena de texto con todos los nombres de implementadores 
  def implementadores_nombre
    implementador.collect{|f| f.nombre}.join(", ")
  end

  # Cadena de texto con todos los nombres de otros implementadores (quitamos al gestor) 
  def otros_implementadores_nombre
    (implementador - [gestor]).collect{|f| f.nombre}.join(", ")
  end

  # Devuelve el presupuesto del financiador principal
  def presupuesto_financiador_principal
    presupuesto_total_con_tc({financiador: agente}).to_f
  end

  # Cadena de texto con todas las monedas locales
  def monedas_definidas
    moneda.collect{|m| m.nombre}.join(", ") 
  end

  # Cadena de texto con todos los paises implicados
  def paises_definidos
    pais.collect{|p| p.nombre}.join(", ")
  end

  # Array con todos los sectores de intervencion implicados
  def sectores_intervencion_definidos
    proyecto_x_sector_intervencion.collect{|p| p.sector_intervencion.nombre + " (" + (p.porcentaje*100).to_s + "%)"}
  end

  # Array con todas las areas de actuacion implicadas
  def areas_actuacion_definidas
    proyecto_x_area_actuacion.collect{|p| p.area_actuacion.nombre + " (" + (p.porcentaje*100).to_s + "%)"}
  end

  # Array con todos los sectores de población implicados
  def sectores_poblacion_definidos
    proyecto_x_sector_poblacion.collect{|p| p.sector_poblacion.nombre + " (" + (p.porcentaje*100).to_s + "%)"}
  end

  # Averigua cuantos gastos de delegacion hay
  def num_gastos_delegaciones
    Gasto.where(:proyecto_origen_id => self.id).joins(:agente).where("agente.socia_local IS NOT TRUE").count
  end

  # Devuelve una cadena con todos los administradores del proyecto ordenados por rol
  def usuarios_administradores
    usuarios = []
    Rol.where(admin: true, seccion: "proyectos").each do |rol|
      uxr = usuario_x_proyecto.where(rol_id: rol.id).collect{|uxp| uxp.usuario.nombre_completo}
      usuarios.push rol.nombre + ": " + uxr.join(", ") unless uxr.empty?
    end
    return usuarios.join("/ ")
  end

  # Devuelve una cadena con los periodos de seguimiento de financiador
  def periodo_seguimiento_financiador
    # OJO!!! Hardcodeamos el tipo de periodo... esto tendria que estar de alguna otra forma
    periodo.where(tipo_periodo_id: 2).collect{|p| _("Desde el %s hasta el %s")%[I18n.l(p.fecha_inicio), I18n.l(p.fecha_fin)]}.join(", ")
  end

  # Devuelve una cadena con los periodos de justificacion del financiador
  def periodo_justificacion_financiador
    # OJO!!! Hardcodeamos el tipo de periodo... esto tendria que estar de alguna otra forma
    periodo.where(tipo_periodo_id: 1).collect{|p| _("Desde el %s hasta el %s")%[I18n.l(p.fecha_inicio), I18n.l(p.fecha_fin)]}.join(", ")
  end

    # Cadena de texto con todo el personal implicado
  def personal_definidos
    personal.collect{|p| p.nombre}.join(", ")
  end

  # Cadena de texto con todo el personal implicado
  def financiadores_definidos
    financiador.collect{|p| p.nombre}.join(", ")
  end

  # Cadena de texto con todo el personal implicado
  def implementadores_definidos
    implementador.collect{|p| p.nombre}.join(", ")
  end

  def objetivos_especificos_definidos
    objetivo_especifico.collect{|o| o.codigo + ": " +o.descripcion}.join(", ")
  end

  def resultados_definidos
    resultado.collect{|r| r.codigo + ": " + r.descripcion}.join(", ")
  end

  def actividades_definidas
    actividad.collect{|a| a.codigo + ": " + a.descripcion}.join(", ")
  end

  def porcentaje_implementadores
    cad_imp_porcentaje_ejec = ""
    implementador.each do |im|
      cad_imp_porcentaje_ejec += im.nombre + " (" + (presupuesto_total_con_tc(:implementador => im) > 0 ? (presupuesto_total_con_tc(:implementador => im) * 100/presupuesto_total_sin_financiador).round.to_s + " %), " : "0 %), ")
    end
    cad_imp_porcentaje_ejec.sub!(/.{1}$/,'')
    resul = cad_imp_porcentaje_ejec[0..-2]
    return resul
  end

  # Devuelve los pares "clave: valor" a incluir en plantillas
  def campos_plantilla
    campos = {
        "proyecto.nombre" => nombre,
        "proyecto.titulo" => titulo.mb_chars.capitalize,
        "proyecto.paises" => paises_definidos,
        "proyecto.presupuesto" => presupuesto_total_con_tc.to_s + " #{moneda_principal.abreviatura}",
        "proyecto.porcentaje" => porcentaje_implementadores,
        "proyecto.personal" => personal_definidos,
        "proyecto.financiadores" => financiadores_definidos,
        "proyecto.fechas" => fecha_de_inicio.to_s + " / " + fecha_de_fin.to_s ,
        "proyecto.implementadores" => implementadores_definidos,
        "proyecto.objetivo_general" => objetivo_general ? objetivo_general.descripcion : "",
        "proyecto.objetivos_especificos" => objetivos_especificos_definidos,
        "proyecto.resultados" => resultados_definidos,
        "proyecto.actividades" => actividades_definidas,
    }
    return campos
  end

  # Recalcula la tasa de cambio aplicada a cada gasto en el proyecto
  def actualiza_tasa_cambio_gastos
    gasto_x_proyecto.each do |gxp|
      gxp.actualiza_tasa_cambio
      gxp.save
      errors.add :base, _("Errores cambiando TC para GXP %{gxpid}: %{texto}")%{gxpid: gxp.id, texto: gxp.errors.inspect} unless gxp.errors.empty?
    end
  end

  # Revisa todas las lineas de presupuesto e indica los errores que puedan contener
  def valida_presupuesto
    presupuesto.each do |linea|
      # Valida el presupuesto por actividad
      errors.add :base, _("Errores en desglose por actividades para el presupuesto '%{concepto}' (%{partida})")%
                         {concepto: linea.concepto, partida: linea.partida.codigo_nombre} unless linea.comprobar_actividades
      # Valida el presupuesto por financiador
      errors.add :base, _("Errores en desglose por financiadores para el presupuesto '%{concepto}' (%{partida})")%
                         {concepto: linea.concepto, partida: linea.partida.codigo_nombre} unless linea.comprobar_financiadores
      # Valida el presupuesto detallado
      errors.add :base, _("Errores en detalle mensual para el presupuesto '%{concepto}' (%{partida})")%
                         {concepto: linea.concepto, partida: linea.partida.codigo_nombre} unless linea.comprobar_presupuesto_detallado
    end
  end
  # Revisa los porcentajes de sector, area y poblacion e indica si no estan al 100%
  def valida_porcentajes_relaciones
    # Valida que este definido el sector de intervencion al 100%
    if GorConfig.getValue(:VALIDATE_CRS_CODE_ON_APPROVED_PROJECT) == "TRUE" && proyecto_x_sector_intervencion.sum{|r| r.porcentaje} != 1.0
      errors.add :base, _("El proyecto no tiene definidos al 100% los Sectores de Intervención.")
    end
    # Valida que este definida el area de actuacion al 100%
    if GorConfig.getValue(:VALIDATE_AREA_OF_ACTION_ON_APPROVED_PROJECT) == "TRUE" && proyecto_x_area_actuacion.sum{|r| r.porcentaje} != 1.0
      errors.add :base, _("El proyecto no tiene definidas al 100% las Áreas de Actuación.")
    end 
    # Valida que este definida el area de actuacion al 100%
    if GorConfig.getValue(:VALIDATE_POPULATION_SECTOR_ON_APPROVED_PROJECT) == "TRUE" && proyecto_x_sector_poblacion.sum{|r| r.porcentaje} != 1.0
      errors.add :base, _("El proyecto no tiene definidos al 100% los Sectores de Población.")
    end
  end

 private

  def cambiar_monedas
    # Se asegura de que la moneda principal este asignada
    ProyectoXMoneda.find_or_create_by_proyecto_id_and_moneda_id(self.id, self.moneda_id) if moneda_id_changed? && moneda_id
    # Y tambien la divisa
    ProyectoXMoneda.find_or_create_by_proyecto_id_and_moneda_id(self.id, self.moneda_intermedia_id) if moneda_intermedia_id_changed? && moneda_intermedia_id
    # Y el financiador principal
    ProyectoXFinanciador.find_or_create_by_proyecto_id_and_agente_id(self.id, self.agente.id) if convocatoria_id_changed? && convocatoria_id
    # Y el pais
    #ProyectoXPais.find_or_create_by_proyecto_id_and_pais_id(self.id, self.pais_id) if pais_id_changed? && pais_id 
    ProyectoXPais.find_or_create_by_proyecto_id_and_pais_id(self.id, self.pais_principal_id) if pais_principal_id_changed? && pais_principal_id
    # Y el libro del financiador
    libro_financiador = libro_id_changed? && libro_id ? Libro.find_by_id(self.libro_id) : nil
    if libro_financiador
      LibroXProyecto.find_or_create_by_proyecto_id_and_libro_id(self.id, self.libro_id)
      # Y el agente del libro del financiador como financiador (si lo es)
      ProyectoXFinanciador.find_or_create_by_proyecto_id_and_agente_id(self.id, libro_financiador.agente_id) if libro_financiador && libro_financiador.agente && libro_financiador.agente.financiador
      # Y el agente del libro del financiador como implementador (si lo es)
      ProyectoXImplementador.find_or_create_by_proyecto_id_and_agente_id(self.id, libro_financiador.agente_id) if libro_financiador && libro_financiador.agente && libro_financiador.agente.implementador
    end

    # Para modificaciones de proyecto que incluyan moneda principal, actualiza las tasas de cambio
    self.etapa.each { |e| TasaCambio.cambia_moneda(e) } if id_was && moneda_id_changed?
  end

  def verificar_borrado
    #if self.datos_proyecto
    #  (DatosProyecto.column_names - ["id", "proyecto_id"]).each do |v|
    #    if not self.datos_proyecto.send( v.to_sym ).nil?
    #      errors.add( "datos_proyecto","hay datos de proyecto " + v.humanize )
    #    end
    #  end
    #end
   #errors.add( "gasto", "hay gastos" ) unless self.gasto_x_proyecto.empty?
   #errors.add( "presupuesto", "hay presupuestos" ) unless self.presupuesto.empty?
   #errors.add( "objetivo_especifico", "hay objetivos especificos" ) unless self.objetivo_especifico.empty?
   #errors.add( "tarea", "hay tareas" ) unless self.tarea.empty?

   # validacion de documentos (no podemos confiar en la validacion del espacio porque hay documentos sin espacios en el proyecto)
   errors.add( "documento", _("Existen documentos vinculados al proyecto.") ) unless self.documento.empty?
   errors[:base] << _("Un proyecto tiene que estar vacío para poder ser borrado.") unless errors.empty?
   return errors.empty?
 end

 # Limpia los gastos introducidos desde el proyecto.
 # Primero intenta borrarlos, pero si el agente al que pertenecen tiene la etapa cerrada o estaba cofinanciado por otro proyecto los vincula al agente
 def limpia_gastos
   Gasto.where(:proyecto_origen_id => self.id).each do |g|
     # Si el gasto no estaba cofinanciado, lo borra
     if g.gasto_x_proyecto.empty?
       g.evitar_validacion_plugins = true
       g.destroy
     # Si no, se lo asigna al agente o al primer proyecto que haya si el implantador es una socia local
     else
       nuevo_p_origen = g.agente.socia_local ? g.gasto_x_proyecto.first.proyecto_id : nil
       g.update_attributes proyecto_origen_id: nuevo_p_origen, evitar_validacion_plugins: true
       g.comentario.create :texto => _("Gasto proveniente del proyecto borrado: %{nombre}")%{:nombre => self.nombre}
     end
   end 
 end

 #def pais_principal
 # return  (pais_principal_id ? Pais.find_by_pais_principal_id(pais_principal_id).nombre : "")
 #end
 # Permite la ejecucion de metodos de plugins no existentes en el modelo
 # def method_missing(method_sym, *arguments, &block)
 #   clase = nil
 #   # Primero averigua que plugins tienen la clase "Gasto" y cuales de ellos el metodo pedido
 #   Plugin.activos.each do |plugin|
 #     begin
 #       clase = plugin.clase if eval(plugin.clase)::Proyecto.respond_to?(method_sym)
 #     rescue => ex
 #     end
 #   end
 #   # Invoca al ultimo plugin que haya encontrado (o al super si no hay ninguno)
 #   clase ? eval(clase)::Proyecto.send(method_sym,self) : super
 # end
 
 

end
