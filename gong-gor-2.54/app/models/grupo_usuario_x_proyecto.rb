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
# ActiveResource que devuelve grupos vinculados a proyectos

class GrupoUsuarioXProyecto < ActiveRecord::Base

  belongs_to :grupo_usuario
  belongs_to :proyecto
  belongs_to :rol_asignado, :class_name => "Rol", :foreign_key => "rol_id"
  validates_presence_of :grupo_usuario_id, :message => _("Grupo") + " " + _("no puede estar vacío.")
  validates_presence_of :proyecto_id, :message => _("Proyecto") + " " + _("no puede estar vacío.")
  validates_presence_of :rol_id, :mensaje => _("Rol") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :grupo_usuario_id, :scope => :proyecto_id, :message => _("Grupo repetido.")
  validates_associated :rol_asignado, message: _("El rol asignado no es válido.")

  after_save :actualiza_usuario_x_objeto
  after_destroy :elimina_usuario_x_objeto

  # Nos permite almacenar notificar para luego poder propagarlo en las vinculaciones de cada grupo
  attr_accessor :notificar_comentario
  attr_accessor :notificar_estado
  attr_accessor :notificar_usuario
  

  # Hacemos esto por compatibilidad
  def rol
    rol_asignado.nombre.downcase
  end

 private

  # Actualiza las relaciones de usuario_x
  def actualiza_usuario_x_objeto
    grupo_usuario.usuario.each do |usuario|
      ux   = UsuarioXProyecto.find_by_usuario_id_and_proyecto_id_and_grupo_usuario_id(usuario.id, self.proyecto_id, self.grupo_usuario_id)
      ux ||= UsuarioXProyecto.new(usuario_id: usuario.id, proyecto_id: proyecto_id, grupo_usuario_id: grupo_usuario_id)
      ux.update_attributes(rol_id: self.rol_id, notificar_comentario: @notificar_comentario, notificar_estado: @notificar_estado, notificar_usuario: @notificar_usuario)
    end
  end

  # Elimina las relaciones de usuario_x
  def elimina_usuario_x_objeto
    grupo_usuario.usuario.each do |usuario|
      ux = UsuarioXProyecto.find_by_usuario_id_and_proyecto_id_and_grupo_usuario_id(usuario.id, self.proyecto_id, self.grupo_usuario_id)
      ux.destroy if ux
    end
  end
end

