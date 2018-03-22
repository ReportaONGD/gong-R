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
class Webservice::ApiDocsController < Webservice::ApplicationController
	include Webservice::Swagger::ApiDocs
  include Swagger::Blocks

  skip_before_filter :autorizar, :sesion_timeout, :xls_request, :por_pagina, :autorizar_rol
  # doorkeeper_for :all

  def index
		 render json: root_json
  end

  # def 'oauth2-redirect'
		# respond_to do |format|
		#   format.html # show.html.erb
		#  end
  # end
end
