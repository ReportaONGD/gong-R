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

class GrupoUsuario < ActiveRecord::Base

  before_destroy :verificar_borrado 

  validates_uniqueness_of :nombre, message: _("Nombre repetido.")

  has_many :usuario_x_grupo_usuario
  has_many :usuario, through: :usuario_x_grupo_usuario, order: "nombre"
  has_many :grupo_usuario_x_proyecto
  has_many :proyecto, through: :grupo_usuario_x_proyecto  

  belongs_to :asignar_proyecto_rol, class_name: "Rol", foreign_key: "asignar_proyecto_rol_id"

  # Devuelve un string con los miembros del grupo de usuarios
  def miembros
    usuario.collect{|u| u.nombre}.join(", ")
  end

  # Devuelve todos los usuarios_x (esto esta aqui por compatibilidad de metodos en el controlador de usuarios con proyectos, agentes, etc...)
  def usuario_x_vinculado
    return usuario_x_grupo_usuario
  end

  # Para evitar destruir grupos asignados a proyectos o con usuarios asignados
  def verificar_borrado
    errors[:base] << _("No se pueden borrar el grupo por que tiene usuarios asignados.") if usuario.count > 0
    errors[:base] << _("No se puede borrar el grupo por que esta asignado a algun proyecto.") if proyecto.count > 0
    return errors.empty?
  end

end

