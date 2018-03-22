# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2014 Red.es 
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
# Plugin de webservices para informes AECID 

require "webservice/engine"

module Webservice
  def self.seccion_menu usuario=nil, secciones=[]
    # Coloca el boton de informe justo antes del boton de "salir"
    if usuario && usuario.informes_aecid && ENV['GONGR_URL']
      elemento_salir = secciones.detect{|o| o[:nombre] == 'salir'}
      # Como las secciones estan ordenadas al reves de como se muestra, jugamos con las posiciones para
      # colocar esta seccion justo despues del boton de salir o en la última posicion
      posicion = secciones.index(elemento_salir) || (secciones.size - 1)
      secciones.insert(posicion+1, { nombre: 'informes_aecid', url: ENV['GONGR_URL'], titulo: _('Informes AECID') })
    end
    return secciones
  end
end
