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
# Clase del modelo que gestiona la entidad usuario_x_agente. Esta clase sirve para indicar los agentes asociados a usuario.
class UsuarioXAgente < ActiveRecord::Base
  #untranslate_all
  belongs_to :agente
  belongs_to :usuario
  belongs_to :grupo_usuario
  belongs_to :rol_asignado, :class_name => "Rol", :foreign_key => "rol_id"
  validates_presence_of :usuario_id, :message => _("Usuario") + " " + _("no puede estar vacío.")
  validates_presence_of :agente_id, :message => _("Agente") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :agente_id, :scope => [:usuario_id, :grupo_usuario_id], :message => _("Agente") + " " + _("repetida.")
  validates_associated :rol_asignado, message: _("El rol asignado no es válido.")

  # Esto que pinta aqui?... lo comentamos y lo eliminaremos en el futuro
  #after_create :crear_espacio
  # Si un usuario tiene asignado un agente le creamos la carpeta
  #def crear_espacio
  #  # Si aun no existe un espacio para el agente, lo creamos
  #  unless agente.espacio
  #    espacio_padre = Espacio.find_by_nombre("Agentes").id 
  #    espacio_agente = Espacio.create :nombre => agente.nombre, :agente_id => agente.id, 
  #                     :espacio_padre_id => espacio_padre, :descripcion => ("Espacio raíz del agente: " + agente.nombre)
  #    for espacio in Espacio.find_all_by_definicion_espacio_agente(true)
  #      Espacio.create :nombre => espacio.nombre, :espacio_padre_id => espacio_agente.id, :definicion_espacio_agente_id => espacio.id
  #    end
  #  end
  #end

  # No vale para nada, pero es para simplificar las cosas en el controlad
  attr_accessor :notificar

  # Hacemos esto por compatibilidad
  def rol
    rol_asignado.nombre.downcase
  end

end
