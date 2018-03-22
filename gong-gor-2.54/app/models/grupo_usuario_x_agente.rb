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
# ActiveResource que devuelve grupos vinculados a agentes 

class GrupoUsuarioXAgente < ActiveRecord::Base

  belongs_to :grupo_usuario
  belongs_to :agente
  belongs_to :rol_asignado, :class_name => "Rol", :foreign_key => "rol_id"
  validates_presence_of :grupo_usuario_id, :message => _("Grupo") + " " + _("no puede estar vacío.")
  validates_presence_of :agente_id, :message => _("Agente") + " " + _("no puede estar vacío.")
  validates_presence_of :rol_id, :mensaje => _("Rol") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :grupo_usuario_id, :scope => :agente_id, :message => _("Grupo repetido.")
  validates_associated :rol_asignado, message: _("El rol asignado no es válido.")

  after_save :actualiza_usuario_x_objeto
  after_destroy :elimina_usuario_x_objeto

  # No vale para nada, pero es para simplificar las cosas en el controlador
  attr_accessor :notificar

  # Hacemos esto por compatibilidad
  def rol
    rol_asignado.nombre.downcase
  end

 private

  # Actualiza las relaciones de usuario_x
  def actualiza_usuario_x_objeto
    grupo_usuario.usuario.each do |usuario|
      ux   = UsuarioXAgente.find_by_usuario_id_and_agente_id_and_grupo_usuario_id(usuario.id, self.agente_id, self.grupo_usuario_id)
      ux ||= UsuarioXAgente.new(usuario_id: usuario.id, agente_id: agente_id, grupo_usuario_id: grupo_usuario_id)
      ux.update_attribute(:rol_id, self.rol_id)
    end
  end

  # Elimina las relaciones de usuario_x
  def elimina_usuario_x_objeto
    grupo_usuario.usuario.each do |usuario|
      ux = UsuarioXAgente.find_by_usuario_id_and_agente_id_and_grupo_usuario_id(usuario.id, self.agente_id, self.grupo_usuario.id)
      ux.destroy if ux
    end
  end

end

