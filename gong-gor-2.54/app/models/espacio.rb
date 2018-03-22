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
class Espacio < ActiveRecord::Base
  before_destroy :espacio_raiz_de_agente, :espacio_raiz_de_proyecto, :espacio_raiz_de_pais, :espacio_vacio, :espacio_borrable, :borra_espacios_automaticos

  belongs_to :espacio_padre, :class_name => 'Espacio' , :foreign_key => 'espacio_padre_id'
  has_many :espacio_hijo, :class_name => 'Espacio', :order => 'nombre', :foreign_key => 'espacio_padre_id', :dependent => :destroy

  has_many :espacios_definidos_proyecto, :class_name => 'Espacio', :order => 'nombre', :foreign_key => 'definicion_espacio_proyecto_id'
  has_many :espacios_definidos_pais, :class_name => 'Espacio', :order => 'nombre', :foreign_key => 'definicion_espacio_pais_id'
  has_many :espacios_definidos_agente, :class_name => 'Espacio', :order => 'nombre', :foreign_key => 'definicion_espacio_agente_id'
  has_many :espacios_definidos_socia, :class_name => 'Espacio', :order => 'nombre', :foreign_key => 'definicion_espacio_socia_id'
  has_many :espacios_definidos_financiador, :class_name => 'Espacio', :order => 'nombre', :foreign_key => 'definicion_espacio_financiador_id'

  # Esta relacion la usamos en algun momento?. Funciona?
  belongs_to :definicion_proyecto, :class_name => 'Espacio', :foreign_key => 'definicion_espacio_proyecto_id'
  belongs_to :definicion_pais, :class_name => 'Espacio' , :foreign_key => 'definicion_espacio_pais_id'
  belongs_to :definicion_agente, :class_name => 'Espacio' , :foreign_key => 'definicion_espacio_agente_id'
  belongs_to :definicion_socia, :class_name => 'Espacio', :foreign_key => 'definicion_espacio_socia_id'
  belongs_to :definicion_financiador, :class_name => 'Espacio' , :foreign_key => 'definicion_espacio_financiador_id'

  #has_many :documento
  has_many :documento_x_espacio
  has_many :documento, :through => :documento_x_espacio
  belongs_to :proyecto
  belongs_to :agente
  belongs_to :pais
  has_many :usuario_x_espacio, :dependent => :destroy
  has_many :usuario, :through => :usuario_x_espacio
  has_many :grupo_usuario_x_espacio, :dependent => :destroy
  has_many :grupo_usuario, :through => :grupo_usuario_x_espacio, :order => "nombre"


  #validate :nombre_mayusculas 
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :nombre,
                          :scope => [:espacio_padre_id, :definicion_espacio_proyecto, :definicion_espacio_agente, :definicion_espacio_socia, :definicion_espacio_financiador, :definicion_espacio_pais], 
                          :message => _("Nombre repetido.")
  #before_validation_on_update :comprobar_estado_padre
  before_validation :comprobar_estado_padre, :on => :update
  after_save :modificar_crear_espacios_automaticos
  after_create :crear_espacios_vinculados


  # Si es una definicion de espacio autumatica: espacio de definicion_espacio_algo, creamos una espacio asociado para cada espacio del algo
  # La nueva creacion de espacios automaticos se propaga en todos los objetos existentes
  def modificar_crear_espacios_automaticos

    # Si es una definicion de espacio para proyectos
    if respond_to?('definicion_espacio_proyecto') && definicion_espacio_proyecto
      # Si tiene espacio padre, los espacios padre seran todos los que sean definicion de ese espacio padre
      if self.espacio_padre_id
        espacios_padre = Espacio.all(:conditions => {:definicion_espacio_proyecto_id => self.espacio_padre_id })
      # Si no hay espacio padre, los espacios padre seran los paises 
      else
        espacios_padre = Espacio.all(:conditions => "proyecto_id is not NULL")
      end
      # Recorremos todos los espacios padre donde trabajar
      for espacio_contenedor in espacios_padre
        if self.id_was.nil?
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_nombre(espacio_contenedor.id, nombre)
          espacio.update_attributes :definicion_espacio_proyecto_id => id
        else
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_definicion_espacio_proyecto_id(espacio_contenedor.id, id)
        end
        espacio.update_attributes nombre: nombre, ocultar: ocultar, descripcion: descripcion, espacio_contratos: espacio_contratos
        espacio.errors.each {|e, m|  errors.add "", m }
      end
    end

    # Si es una definicion de espacio para paises
    if respond_to?('definicion_espacio_pais') && definicion_espacio_pais
      # Si tiene espacio padre, los espacios padre seran todos los que sean definicion de ese espacio padre
      if self.espacio_padre_id
        espacios_padre = Espacio.all(:conditions => {:definicion_espacio_pais_id => self.espacio_padre_id })
      # Si no hay espacio padre, los espacios padre seran los paises 
      else
        espacios_padre = Espacio.all(:conditions => "pais_id is not NULL")
      end
      # Recorremos todos los espacios padre donde trabajar
      for espacio_contenedor in espacios_padre
        if self.id_was.nil?
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_nombre(espacio_contenedor.id, nombre)
          espacio.update_attributes :definicion_espacio_pais_id => id
        else
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_definicion_espacio_pais_id(espacio_contenedor.id, id)
        end
        espacio.update_attributes :nombre => nombre, :ocultar => ocultar, :descripcion => descripcion
        espacio.errors.each {|e, m|  errors.add "", m }
      end
    end

    # Si es una definicion de estado para delegaciones 
    if respond_to?('definicion_espacio_agente') && definicion_espacio_agente
      # Si tiene espacio padre, los espacios padre seran todos los que sean definicion de ese espacio padre
      if self.espacio_padre_id
        espacios_padre = Espacio.all(:conditions => {:definicion_espacio_agente_id => self.espacio_padre_id })
      # Si no hay espacio padre, los espacios padre seran los implementadores
      else
        espacios_padre = Espacio.joins(:agente).where("agente.implementador" => true, "agente.socia_local" => false) 
      end
      # Recorremos todos los espacios padre donde trabajar
      for espacio_contenedor in espacios_padre
        if self.id_was.nil?
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_nombre(espacio_contenedor.id, nombre)
          espacio.update_attributes :definicion_espacio_agente_id => id
        else
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_definicion_espacio_agente_id(espacio_contenedor.id, id)
        end
        espacio.update_attributes nombre: nombre, ocultar: ocultar, descripcion: descripcion, espacio_contratos: espacio_contratos
        espacio.errors.each {|e, m|  errors.add "", m }
      end
    end

    # Si es una definicion de estado para socias
    if respond_to?('definicion_espacio_socia') && definicion_espacio_socia
      # Si tiene espacio padre, los espacios padre seran todos los que sean definicion de ese espacio padre
      if self.espacio_padre_id
        espacios_padre = Espacio.all(:conditions => {:definicion_espacio_socia_id => self.espacio_padre_id })
      # Si no hay espacio padre, los espacios padre seran las socias
      else
        espacios_padre = Espacio.joins(:agente).where("agente.implementador" => true, "agente.socia_local" => true)
      end
      # Recorremos todos los espacios padre donde trabajar
      for espacio_contenedor in espacios_padre
        if self.id_was.nil?
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_nombre(espacio_contenedor.id, nombre)
          espacio.update_attributes :definicion_espacio_socia_id => id
        else
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_definicion_espacio_socia_id(espacio_contenedor.id, id)
        end
        espacio.update_attributes :nombre => nombre, :ocultar => ocultar, :descripcion => descripcion
        espacio.errors.each {|e, m|  errors.add "", m }
      end
    end

    # Si es una definicion de estado para financiadores 
    if respond_to?('definicion_espacio_financiador') && definicion_espacio_financiador
      # Si tiene espacio padre, los espacios padre seran todos los que sean definicion de ese espacio padre
      if self.espacio_padre_id
        espacios_padre = Espacio.all(:conditions => {:definicion_espacio_financiador_id => self.espacio_padre_id })
      # Si no hay espacio padre, los espacios padre seran los financiadores 
      else
        espacios_padre = Espacio.joins(:agente).where("agente.financiador and (not agente.implementador or agente.implementador is null)")
      end
      # Recorremos todos los espacios padre donde trabajar
      for espacio_contenedor in espacios_padre
        if self.id_was.nil?
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_nombre(espacio_contenedor.id, nombre)
          espacio.update_attributes :definicion_espacio_financiador_id => id
        else
          espacio = Espacio.find_or_create_by_espacio_padre_id_and_definicion_espacio_financiador_id(espacio_contenedor.id, id)
        end
        espacio.update_attributes :nombre => nombre, :ocultar => ocultar, :descripcion => descripcion
        espacio.errors.each {|e, m|  errors.add "", m }
      end
    end
  end

  # Si creamos un espacio vinculado a una definicion de espacio automatica, intentamos crear los hijos tambien
  # La nueva creacion de un espacio de pais, agente, proyecto, copia tambien los hijos 
  def crear_espacios_vinculados
    # Si es un espacio vinculado a una definicion de espacio para proyectos
    if respond_to?('definicion_espacio_proyecto_id') && definicion_proyecto
      # Va recorriendo todos los hijos del espacio de automatico y creandolos
      definicion_proyecto.espacio_hijo.each do |eh|
        neh = Espacio.create espacio_padre_id: self.id, nombre: eh.nombre, descripcion: eh.descripcion,
                             definicion_espacio_proyecto_id: eh.id, ocultar: eh.ocultar, espacio_contratos: eh.espacio_contratos
        neh.errors.each {|e,m|  errors.add "", m}
      end
    end
    # Si es un espacio vinculado a una definicion de espacio para paises 
    if respond_to?('definicion_espacio_pais_id') && definicion_pais
      # Va recorriendo todos los hijos del espacio de automatico y creandolos
      definicion_pais.espacio_hijo.each do |eh|
        neh = Espacio.create :espacio_padre_id => self.id, :nombre => eh.nombre, :definicion_espacio_pais_id => eh.id, :ocultar => eh.ocultar, :descripcion => eh.descripcion
        neh.errors.each {|e,m|  errors.add "", m}
        # Vinculamos los usuarios
        if neh.errors.empty?
        end
      end
    end
    # Si es un espacio vinculado a una definicion de espacio para financiadores
    if respond_to?('definicion_espacio_financiador_id') && definicion_financiador
      # Va recorriendo todos los hijos del espacio de automatico y creandolos
      definicion_financiador.espacio_hijo.each do |eh|
        neh = Espacio.create :espacio_padre_id => self.id, :nombre => eh.nombre, :definicion_espacio_financiador_id => eh.id, :ocultar => eh.ocultar, :descripcion => eh.descripcion
        neh.errors.each {|e,m|  errors.add "", m}
        # Vinculamos los usuarios
        if neh.errors.empty?
        end
      end
    end
    # Si es un espacio vinculado a una definicion de espacio para delegaciones
    if respond_to?('definicion_espacio_agente_id') && definicion_agente
      # Va recorriendo todos los hijos del espacio de automatico y creandolos
      definicion_agente.espacio_hijo.each do |eh|
        neh = Espacio.create espacio_padre_id: self.id, nombre: eh.nombre, descripcion: eh.descripcion,
                             definicion_espacio_agente_id: eh.id, ocultar: eh.ocultar, espacio_contratos: eh.espacio_contratos
        neh.errors.each {|e,m|  errors.add "", m}
      end
    end
    # Si es un espacio vinculado a una definicion de espacio para socias
    if respond_to?('definicion_espacio_socia_id') && definicion_socia
      # Va recorriendo todos los hijos del espacio de automatico y creandolos
      definicion_socia.espacio_hijo.each do |eh|
        neh = Espacio.create :espacio_padre_id => self.id, :nombre => eh.nombre, :definicion_espacio_socia_id => eh.id, :ocultar => eh.ocultar, :descripcion => eh.descripcion
        neh.errors.each {|e,m|  errors.add "", m}
      end
    end
  end

  # Si es un espacio de definicion_espacio_algo eliminamos un espacio igual por cada algo. Siempre y cuando no contenga documentos. 
  def borra_espacios_automaticos
    for espacio in  espacios_definidos_proyecto
      espacio.destroy
      espacio.errors.each {|e, m|  errors.add "", m }
    end if definicion_espacio_proyecto

    for espacio in  espacios_definidos_pais
      espacio.destroy
      espacio.errors.each {|e, m|  errors.add "", m }
    end if definicion_espacio_pais

    for espacio in  espacios_definidos_agente
      espacio.destroy
      espacio.errors.each {|e, m|  errors.add "", m }
    end if definicion_espacio_agente

    for espacio in espacios_definidos_socia
      espacio.destroy
      espacio.errors.each {|e, m|  errors.add "", m }
    end if definicion_espacio_socia

    for espacio in  espacios_definidos_financiador
      espacio.destroy
      espacio.errors.each {|e, m|  errors.add "", m }
    end if definicion_espacio_financiador
  end

  # Comprobaciones previas al borrado 
  def espacio_raiz_de_proyecto
    #errors.add(:base, _("Espacio asociado a proyecto. No se puede borrar")) if proyecto_id
    #return  (proyecto_id ? false : true)
  end

  # Comprobaciones previas al borrado 
  def espacio_raiz_de_agente
    #errors.add(:base, _("Espacio asociado a agente. No se puede borrar")) if agente_id
    #return  (agente_id ? false : true)
  end

  # Comprobaciones previas al borrado 
  def espacio_raiz_de_pais
    #errors.add(:base, _("Espacio asociado a país. No se puede borrar")) if pais_id
    #return  (pais_id ? false : true)
  end

  # Comprobaciones previas al borrado  
  def espacio_vacio
    unless documento.empty?
      msg_error = _("El espacio %{ruta} contiene documentos: no se puede eliminar") % {:ruta => self.ruta + " / " + self.nombre}
      # Revisar porque no funciona esto (no se muestra el error en proyecto)
      errors.add :base, msg_error
      # Ni esto tampoco funciona (proyecto no pilla el error)
      #proyecto_del_espacio.errors.add(:base, msg_error) if proyecto_del_espacio
      #agente_del_espacio.errors.add(:base, msg_error) if agente_del_espacio
      #pais_del_espacio.errors.add(:base, msg_error) if pais_del_espacio
    end
    return (documento.empty?)
  end

  # Comprueba que el espacio sea borrable
  def espacio_borrable
    errors.add(:base, _("Este espacio esta definido como no modificable")) unless modificable
    return modificable
  end

  def nombre_mayusculas
    self.nombre = self.nombre.upcase
  end

  def directory?
    true
  end

  # Devuelve los usuarios_x_ vinculados directamente (no a traves de grupo)
  def usuario_x_vinculado
    return usuario_x_espacio.where(:grupo_usuario_id => nil)
  end

  def ruta
      (((espacio_padre.ruta || "") + " / " + espacio_padre.nombre) if espacio_padre) || ""
  end

  def ruta_con_id
    ( espacio_padre.ruta_con_id + [{:nombre => espacio_padre.nombre, :id => espacio_padre.id}] if espacio_padre ) || [{:nombre => _("Raíz"), :id => nil}]
  end

  def proyecto_del_espacio
    proyecto || (espacio_padre ? espacio_padre.proyecto_del_espacio : nil)
  end

  def agente_del_espacio
    agente || (espacio_padre ? espacio_padre.agente_del_espacio : nil)
  end

  def pais_del_espacio
    pais || (espacio_padre ? espacio_padre.pais_del_espacio : nil)
  end
  
  def comprobar_estado_padre
    errors.add( "estado_superior_id", _("No puede tener como espacio 'superior' el espacio seleccionado"))  if (espacio_padre.ruta.include?(Espacio.find(id).nombre) or espacio_padre_id == id) if espacio_padre
    return false unless errors.empty?
  end

  def usuario_no_permitido user
    # Por defecto rechazamos
    denegado = true
    # Para espacios de proyectos
    if (proy=proyecto_del_espacio) && !ocultar 
      # Permitimos segun pertenezca
      #denegado = !(proy.usuario_autorizado? user)
      # Permitimos siempre
      denegado = false
    # Para espacios de agentes (debe estar antes de pais para no heredar)
    elsif (agt=agente_del_espacio) && !ocultar
      # Por defecto, autorizamos
      denegado = false
      # Si es implementador, miramos segun pertenezca o no el agente
      #denegado = !(agt.usuario_autorizado? user) if agt.implementador
      # Si no es implementador, le dejamos pasar
      #denegado = false unless agt.implementador
    elsif (pai=pais_del_espacio) && !ocultar
      # Por defecto, autorizamos 
      denegado = false 
      # Obtenemos todos los implementadores del país comprobando que el usuario este autorizado
      # Comentamos lo siguiente para autorizar por defecto
      #pai.agente.each { |agt| denegado = false if agt.usuario_autorizado? user }
    # Para el resto de espacios o espacios ocultos
    elsif ( definicion_espacio_financiador_id  || definicion_espacio_pais_id )
      esp_vinculado = Espacio.find_by_id( definicion_espacio_financiador_id ) if definicion_espacio_financiador_id
      esp_vinculado = Espacio.find_by_id( definicion_espacio_pais_id ) if definicion_espacio_pais_id
      denegado = (ocultar and !(esp_vinculado.usuario.include? user)) if esp_vinculado
    else
      #puts "-------------> El espacio " + self.nombre + " esta " + (ocultar ? "OCULTO" : "ABIERTO") + " y el usuario " + ((usuario.include? user) ? "PERTENECE" : "NO PERTENECE")
      denegado = (ocultar and !(proy.usuario_autorizado? user)) if proy
      denegado = (ocultar and !(agt.usuario_autorizado? user)) if agt && agt.implementador
      denegado = (ocultar and !(usuario.include? user)) unless proy || (agt && agt.implementador)
    end
    return denegado
  end

  def escritura_permitida user
    # Por defecto rechazamos
    autorizado = false
    # Para espacios de proyectos
    if proj=proyecto_del_espacio 
      # Y permitimos segun pertenezca
      autorizado = proj.usuario_autorizado? user
    # Para espacios de agentes implementadores
    elsif (agt=agente_del_espacio) && agt.implementador
      # Si es implementador, miramos segun pertenezca o no el agente
      autorizado = agt.usuario_autorizado? user
    elsif (pai=pais_del_espacio) && !ocultar
      # Obtenemos todos los implementadores del país comprobando que el usuario este autorizado
      pai.agente.each { |agt| autorizado = agt.usuario_autorizado?(user) }
    # Para el resto de espacios
    elsif ( definicion_espacio_financiador_id || definicion_espacio_pais_id )
      # Si es un espacio vinculado a un financiador o a un pais, validamos según los permisos de su vinculado
      esp_vinculado = Espacio.find_by_id( definicion_espacio_financiador_id ) if definicion_espacio_financiador_id
      esp_vinculado = Espacio.find_by_id( definicion_espacio_pais_id ) if definicion_espacio_pais_id
      autorizado = esp_vinculado.usuario.include?(user) if esp_vinculado
    else
      #puts "-------------> En el espacio " + self.nombre + " el usuario " + ((usuario.include? user) ? "PERTENECE" : "NO PERTENECE")
      autorizado = usuario.include? user
    end
    #puts "-----------> El usuario " + user.nombre + " " + (autorizado ? "esta" : "no esta") + " autorizado"
    return autorizado 
  end

  # +++
  # Sobrecargamos la clase para obtener espacios y documentos de un espacio dado
  # ---
  def self.contenido current_user=nil, espacio_id=nil, administracion=false, orden=nil
    esp = esp_virt = []

    # Recorremos las posiblidades segun el espacio_id enviado
    # Para espacios virtuales de contrato...
    if (espacio_id && (obj_id = espacio_id.to_s.match(/^CONTRATO_(\d+)_ID_(\d+)$/)))
      # Comprobamos que tanto el contrato como el espacio padre existan y sea accesible por el usuario
      contrato = Contrato.find_by_id(obj_id[1])
      espacio_padre = Espacio.find_by_id(obj_id[2])
      if contrato.nil? || espacio_padre.nil? || espacio_padre.usuario_no_permitido(current_user)
        espacio = nil
        documentos = []
      else
        # Generamos un espacio false para poder ubicar las cosas
        espacio = Espacio.new(nombre: (contrato.codigo||"_SC_"+contrato.id.to_s), espacio_padre_id: espacio_padre.id)
        # Obtenemos los documentos del espacio
        documentos = Documento.joins(contrato_x_documento: :contrato).where("contrato.id" => obj_id[1])
      end
    # Para cualquier otro caso
    else
      # Si estamos en administracion forzamos siempre estar en el mismo espacio
      espacio = Espacio.find_by_id(espacio_id) if espacio_id
      # Salvo que estemos administrando espacios, evita que un no autorizado entre en el espacio
      espacio = nil if espacio && !administracion && espacio.usuario_no_permitido(current_user)
      #documentos = espacio ? espacio.reload.documento.joins(:usuario).order(orden) : []
      documentos = espacio ? espacio.reload.documento.order(orden) : []
      condiciones = ['espacio_padre_id = ?', espacio.id ] if espacio
      condiciones = '(espacio_padre_id is NULL or espacio_padre_id = "0") and
                     (definicion_espacio_proyecto is NULL or definicion_espacio_proyecto = "0") and 
                     (definicion_espacio_agente is NULL or definicion_espacio_agente = "0") and
                     (definicion_espacio_socia is NULL or definicion_espacio_socia = "0") and
                     (definicion_espacio_financiador is NULL or definicion_espacio_financiador = "0") and
                     (definicion_espacio_pais is NULL or definicion_espacio_pais = "0")' unless espacio
      esp = Espacio.where(condiciones).order('nombre')
      # Quitamos los espacios ocultos o aquellos sobre los que no se tienen permisos especificos
      esp.reject! {|e| (e.usuario_no_permitido current_user)}
      # Si es un espacio de contratos, le añadimos todos los espacios virtuales de los contratos relacionados
      if espacio && espacio.espacio_contratos
        # Averigua los contratos del espacio (segun el proyecto o agente al que pertenezca)
        # Si es un proyecto
        if espacio.definicion_espacio_proyecto_id
          contratos = Contrato.where(proyecto_id: espacio.proyecto_del_espacio).order(:codigo)
        # Si es una delegacion
        elsif espacio.definicion_espacio_agente_id
          contratos = Contrato.where(agente_id: espacio.agente_del_espacio).order(:codigo)
        else
          contratos = []
        end
        esp_virt = contratos.collect{|c| {nombre: (c.codigo||"_SC_"+c.id.to_s), id: "CONTRATO_" + c.id.to_s + "_ID_" + espacio.id.to_s, action: 'seleccionar_espacio', descripcion: _("Documentos del contrato '%s'")%[c.nombre]} }
      end
    end
    # Construye el hash para manejar espacios
    espacios = esp.inject(esp_virt) {|m,a| m.push({:nombre => a.nombre, :id => a.id, :action => 'seleccionar_espacio', :descripcion => a.descripcion}) }
    return {:espacio => espacio, :espacios => espacios, :documentos => documentos}
  end

end
