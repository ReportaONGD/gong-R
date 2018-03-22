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
# ActiveResource que devuelve usuarios

class Usuario < ActiveRecord::Base

  before_destroy :verificar_borrado 

  validates_uniqueness_of :nombre, :message => _("Nombre repetido.")
  # Passwd vacia solo cuando no estemos con un usuario identificado fuera
  validates_presence_of :contrasena, :message => _("Contraseña") + " " + _("no puede estar vacía."), :if => lambda { self.external_id.blank? }
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :correoe, :message => _("Correo") + " " + _("no puede estar vacío.")  

  has_many :comentario
  has_many :documento
  has_many :tarea, :dependent => :destroy
  #has_many :usuario_x_financiacion, :dependent => :destroy
  #has_many :financiacion, :through => :usuario_x_financiacion
  has_many :usuario_x_grupo_usuario, :dependent => :destroy
  has_many :grupo_usuario, :through => :usuario_x_grupo_usuario
  has_many :usuario_x_proyecto , :dependent => :destroy
  has_many :usuario_x_agente, :dependent => :destroy
  has_many :usuario_x_libro ,  :dependent => :destroy

  has_many :libro , :through => :usuario_x_libro, :uniq => true 
  has_many :proyecto, :through => :usuario_x_proyecto, :uniq => true 
  has_many :agente, :through => :usuario_x_agente, :order => "nombre", :uniq => true

  # Espacios asignados
  has_many :usuario_x_espacio, :dependent => :destroy
  has_many :espacio, :through => :usuario_x_espacio, :uniq => true

  # Oficina a la que pertenece
  belongs_to :delegacion, class_name: "Agente", foreign_key: :agente_id

  after_destroy :reasigna_documentos

  # Reasigna los documentos del usuario cuando se borra este
  def reasigna_documentos
    documento.each do |docu|
      usr = nil
      # Primero mira si es de un proyecto y lo asigna al primer usuario privilegiado que encuentre 
      if docu.proyecto_id
        uxp = UsuarioXProyecto.where(proyecto_id: docu.proyecto_id).where("usuario_id != ?", id).joins(:rol_asignado).where("rol.admin" => true).first
        usr = uxp ? uxp.usuario : nil
      # O de un agente y lo asigna al primero privilegiado que encuentre
      elsif docu.agente_id
        uxa = UsuarioXAgente.where(agente_id: docu.agente_id).where("usuario_id != ?", id).joins(:rol_asignado).where("rol.admin" => true).first 
        usr = uxa ? uxa.usuario : nil
      end
      # Si sigue sin haber usuario para asignar, mira si esta en un espacio con permisos y lo asigna al primero que haya
      usr ||= docu.espacio.first.usuario.first
      # Y si nada de eso funciona, al primer administrador con acceso tambien a documentacion
      usr ||= Usuario.where(:administracion => true, :documentos => true).first
      docu.update_attributes(:usuario_id => usr.id) if usr
    end
  end
  
  #Para evitar destruir todos los usuarios, dejamos que siempre haya un usuario "admin"
  def verificar_borrado
    errors[:base] << _("No se pueden borrar todos los usuarios administradores.") unless (! self.administracion) || Usuario.where(:administracion => true).count > 1
    return errors.empty? 
  end

  # Metodo que hashea la contraseña
  def self.hash_contrasena(contrasena)
    Digest::SHA1.hexdigest(contrasena)
  end

  # Devuelve un Usuario, o un UsuarioR (dependiento de la variable ALFRESCO) para una contraseña y usuario determinado.
  def self.identificacion(usuario, contrasena)
    identificado = find :first, :conditions => ["nombre = ? AND contrasena = ? AND NOT bloqueado", usuario, hash_contrasena(contrasena)]
    logger.info( ">>>>>>>>>>>>>>>> ERROR!!!!: Intento fallido de autentificacion del usuario: " + usuario.inspect ) unless !identificado.nil?
    return identificado 
  end

  # Devuelve el nombre detallado del usuario (nick + nombre real)
  def nombre_detallado
    return self.nombre + ( self.nombre_completo.blank? ? "" : " ( " + self.nombre_completo + " )")
  end

  # Averigua si el usuario tiene permisos especiales sobre el elemento enviado
  def privilegios_especiales? objeto=nil
    especial = false
    if objeto.class.name == "Agente"
      especial = objeto.usuario_x_agente.
                 where(usuario_id: self.id).
                 joins(:rol_asignado).
                 where("rol.admin" => true).size > 0
    elsif objeto.class.name == "Proyecto"
      especial = objeto.usuario_x_proyecto.
                 where(usuario_id: self.id).
                 joins(:rol_asignado).
                 where("rol.admin" => true).size > 0
    end
    return especial 
  end
end

