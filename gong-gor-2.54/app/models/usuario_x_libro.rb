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
class UsuarioXLibro < ActiveRecord::Base
  #untranslate_all
  belongs_to :libro
  belongs_to :usuario
  belongs_to :grupo_usuario
  validates_presence_of :usuario_id, :message => _("Usuario") + " " + _("no puede estar vacío.")
  validates_presence_of :libro_id, :message => _("Cuenta") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :libro_id, :scope => [:usuario_id, :grupo_usuario_id], :message => _("Cuenta repetida.")

  # Metodo falso para simplificar las cosas en el controlador
  def rol=(cadena)
  end

end


