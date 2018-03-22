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
# Projects Webservice controller
#
# All webservices are available on /webservice/proyectos route
#
# Autorization for all WS are done by GONG OAUTH provider
#
# Returned data is in xml or json format depending the extension of the invoked webservice (ex.):
# * XML Format: /webservice/proyectos/datos_generales.xml
# * JSON Format: /webservice/proyectos/datos_generales.json
#
# Controlador encargado de los webservices.

class Webservice::DocumentosController < Webservice::ApplicationController
  include Webservice::Swagger::DocumentosApi
  skip_before_filter :autorizar, :sesion_timeout, :xls_request, :por_pagina, :autorizar_rol
  doorkeeper_for :all

  respond_to :json, :xml

  def documentos
    proyecto = Proyecto.find params[:proyecto_id]
    @documentos = proyecto.documento
  end

  def documento
    proyecto = Proyecto.find params[:proyecto_id]
    doc = proyecto.documento.find params[:documento_id]
    send_file doc.adjunto.path,
              filename: doc.adjunto_file_name,
              type: doc.adjunto_content_type,
              :disposition => 'attachment'
  end
end
