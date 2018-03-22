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
# Clase del modelo que gestiona la entidad proyecto_x_usuario. Esta clase sirve para indicar los agentes asociados a usuario.
class UsuarioXEspacio < ActiveRecord::Base
  #untranslate_all
  belongs_to :espacio
  belongs_to :usuario
  validates_presence_of :usuario_id, :message => _("Usuario") + " " + _("no puede estar vacío.")
  validates_presence_of :espacio_id, :message => _("Espacio") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :espacio_id, :scope => [:usuario_id, :grupo_usuario_id], :message => _("Espacio") + " " + _("repetido.")

  # Para ciertos espacios, asignamos tambien el usuario a los dependientes
  after_save :asigna_espacios_dependientes, :if => Proc.new {|uxe| uxe.espacio.definicion_espacio_financiador || uxe.espacio.definicion_espacio_pais }
  after_destroy :desasigna_espacios_dependientes, :if => Proc.new {|uxe| uxe.espacio.definicion_espacio_financiador || uxe.espacio.definicion_espacio_pais } 

  # En los espacios vinculados de paises y financiadores, asignamos tambien los usuarios
  def asigna_espacios_dependientes
    if self.espacio.definicion_espacio_pais 
      espacios = Espacio.where(:definicion_espacio_pais_id => self.espacio.id)
    end
    if self.espacio.definicion_espacio_financiador
      espacios = Espacio.where(:definicion_espacio_financiador_id => self.espacio.id) 
    end
    espacios.each{ |esp| UsuarioXEspacio.create(:usuario_id => self.usuario_id, :espacio_id => esp.id, :grupo_usuario_id => self.grupo_usuario_id) }
  end

  # En los espacios vinculados de paises y financiadores, desasignamos tambien los usuarios
  def desasigna_espacios_dependientes
    if self.espacio.definicion_espacio_pais
      espacios = Espacio.where(:definicion_espacio_pais_id => self.espacio.id)
    end
    if self.espacio.definicion_espacio_financiador
      espacios = Espacio.where(:definicion_espacio_financiador_id => self.espacio.id)
    end
    espacios.each { |esp| UsuarioXEspacio.destroy_all(:usuario_id => self.usuario_id, :espacio_id => esp.id, :grupo_usuario_id => self.grupo_usuario_id) }
  end

  # Metodo falso para simplificar las cosas en el controlador
  def rol=(cadena)
  end
end
