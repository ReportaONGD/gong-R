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
# ActiveResource que devuelve grupos vinculados a libros

class GrupoUsuarioXLibro < ActiveRecord::Base

  belongs_to :grupo_usuario
  belongs_to :libro
  validates_presence_of :grupo_usuario_id, :message => _("Grupo") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :grupo_usuario_id, :scope => :libro_id, :message => _("Grupo repetido.")
  validates_associated :grupo_usuario, message: _("El grupo de usuarios no es válido.")
  validates_presence_of :libro_id, :message => _("Libro") + " " + _("no puede estar vacío.")
  validates_associated :libro, message: _("El libro asociado no es válido.")

  after_save :actualiza_usuario_x_objeto
  after_destroy :elimina_usuario_x_objeto

  # Metodo falso para simplificar las cosas en el controlador
  def rol=(cadena)
  end

 private

  # Actualiza las relaciones de usuario_x
  def actualiza_usuario_x_objeto
    grupo_usuario.usuario.each do |usuario|
      UsuarioXLibro.find_or_create_by_usuario_id_and_libro_id_and_grupo_usuario_id(usuario.id, self.libro_id, self.grupo_usuario_id)
    end
  end

  # Elimina las relaciones de usuario_x
  def elimina_usuario_x_objeto
    grupo_usuario.usuario.each do |usuario|
      ux = UsuarioXLibro.find_by_usuario_id_and_libro_id_and_grupo_usuario_id(usuario.id, self.libro_id, self.grupo_usuario_id)
      ux.destroy if ux
    end
  end

end

