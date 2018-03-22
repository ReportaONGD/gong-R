# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2016 Free Software's Seed, OEI
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
# Controlador de identificacion para el api de gong
class Api::CredentialsController < ApplicationController
  skip_before_filter :autorizar, :sesion_timeout, :xls_request, :por_pagina, :autorizar_rol
  doorkeeper_for :all
  
  respond_to     :json

  def me
    # Hacemos una chapu para evitar mostrar la password (esto nos pasa por no usar convenciones :( )
    current_user = current_resource_owner
    current_user.contrasena = nil if current_user
    respond_with current_user
  end

 private

  def current_resource_owner
    Usuario.where(bloqueado: false).find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
end
