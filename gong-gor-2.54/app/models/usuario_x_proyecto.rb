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
# Clase del modelo que gestiona la entidad proyecto_x_usuario. Esta clase sirve para indicar los libros asociados a usuario.
class UsuarioXProyecto < ActiveRecord::Base
  #untranslate_all
  belongs_to :proyecto
  belongs_to :usuario
  belongs_to :grupo_usuario
  belongs_to :rol_asignado, :class_name => "Rol", :foreign_key => "rol_id"
  validates_presence_of :proyecto_id, :message => _("Proyecto") + " " + _("no puede estar vacío.")
  validates_presence_of :usuario_id, :message => _("Usuario") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :usuario_id, :scope => [:proyecto_id,:grupo_usuario_id], :message => _("Usuario repetido.")
  validates_associated :rol_asignado, message: _("El rol asignado no es válido.")

  after_create :crear_asociacion_pacs
  after_update :modificar_asociacion_pacs
  after_destroy :eliminar_asociacion_pacs

  # Hacemos esto por compatibilidad
  def rol
    rol_asignado.nombre.downcase
  end
  def bloqueado
    usuario.bloqueado
  end
  def skype_id
    usuario.skype_id
  end

 private
  def crear_asociacion_pacs
    self.proyecto.pacs.each { |p| p.usuario_x_proyecto.create(usuario_id: self.usuario_id, rol_id: self.rol_id, grupo_usuario_id: self.grupo_usuario_id) } if self.proyecto.convenio?
  end

  def modificar_asociacion_pacs
    self.proyecto.pacs.each do |pac|
      uxp = pac.usuario_x_proyecto.find_or_create_by_usuario_id_and_grupo_usuario_id(self.usuario_id, self.grupo_usuario_id)
      uxp.rol_id = self.rol_id
      uxp.save
    end if self.proyecto.convenio?
  end

  def eliminar_asociacion_pacs
    self.proyecto.pacs.each { |p| UsuarioXProyecto.destroy_all(:proyecto_id => p.id, :usuario_id => self.usuario_id, :grupo_usuario_id => self.grupo_usuario_id) } if self.proyecto.convenio?
  end

end


