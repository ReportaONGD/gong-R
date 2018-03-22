# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed, CENATIC y IEPALA
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
class Tarea < ActiveRecord::Base
  #untranslate_all
  validates_presence_of :titulo, :message => _("Titulo") + " " + _("no puede estar vacío.")

  belongs_to :proyecto
  #belongs_to :financiacion
  belongs_to :agente
  belongs_to :usuario
  belongs_to :tipo_tarea
  belongs_to :estado_tarea
  belongs_to :definicion_estado_tarea
  belongs_to :periodo
  belongs_to :usuario_asignado, :foreign_key => "usuario_asignado_id", :class_name => "Usuario"

  # Auditado de modificaciones
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy

  validate :comprobar_fechas  

  def fecha_creacion
    self.created_at
  end

  def ultima_modificacion
    self.updated_at
  end

  def asignado_a
    self.usuario_asignado.nombre if self.usuario_asignado
  end

  def creado_por
    self.usuario.nombre if self.usuario
  end

  def estado_actual
    self.estado_tarea.nombre if self.estado_tarea
  end

  def nombre_objeto_relacionado
    (self.proyecto || self.agente).nombre
  end

  def estado_color
    color = ""
    hoy = Date.today
    if fecha_fin && fecha_inicio 
      if hoy > fecha_inicio && hoy < fecha_fin
        color = "verde"
      elsif hoy > fecha_fin
        color = "rojo"
      end
    end unless estado_tarea && !estado_tarea.activo
    return color
  end
  
  private

   def comprobar_fechas
     # Primero comprobamos que existen fechas que comprobar. Si no hubiese fechas ya hay comrpobaciones que impiden guardar.
     if fecha_inicio && fecha_fin 
       if fecha_fin < fecha_inicio
         # Comprueba que la fecha de inicio sea anterior a la de fin
         errors.add("fecha_fin", _("Fecha fin tiene que ser mayor que fecha inicio"))
       end
     end
     return errors.nil?
   end
  

end
