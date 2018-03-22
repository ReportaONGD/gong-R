# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed
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

# Definición de roles
class Rol < ActiveRecord::Base

  has_many :permiso_x_rol, order: [:menu, :controlador], dependent: :destroy
  has_many :usuario_x_proyecto
  has_many :usuario_x_agente
  has_many :grupo_usuario_automatico, class_name: "GrupoUsuario", foreign_key: "asignar_proyecto_rol_id", dependent: :nullify

  validates_presence_of :nombre, message: _("Nombre") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :nombre, scope: [:seccion], message: _("El rol ya está creado en esa sección.")
  validates_presence_of :seccion, message: _("Sección") + " " + _("no puede estar vacía.")

  SECCIONES = { "proyectos" => _('Gestión de Proyectos'), "agentes" => _('Gestión de Agentes y Delegaciones') }

  # Devuelve el nombre humanizado de la sección
  def nombre_seccion
    Rol::SECCIONES[self.seccion]
  end

  # Copia todos los permisos desde otro rol
  def copiar_permisos_desde rol
    if rol && rol.class.name == "Rol" && rol.seccion == self.seccion
      rol.permiso_x_rol.each do |permiso|
        nuevo = permiso.dup
        nuevo.rol_id = self.id
        nuevo.save
      end
    end 
  end
end
