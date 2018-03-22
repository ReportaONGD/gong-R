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
# Controlador encargado de la gestión de los documentos.
# Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para crear una etiqueta, etiquetar un documento, borrar una etiqueta
# * Sección financiaciones: se utiliza para crear una etiqueta, etiquetar un documento, borrar una etiqueta
class EtiquetaController < ApplicationController
  # --
  ########## gestión de etiquetas ##########
  # ++

	# en proyectos y en financiación: se redirecciona por defecto a ordenado
  def index
    redirect_to :action => :listado 
  end

	# en proyectos y en financiación: lista las etiquetas del proyecto o de la financiacion 
  def listado
    session[:etiqueta_asc_desc] ||= "ASC"
    session[:etiqueta_orden] ||= "nombre"
    @etiquetas = @paginado =  Etiqueta.order(session[:etiqueta_orden] + " " + session[:etiqueta_asc_desc]).
                                       paginate(page: params[:page], per_page: (session[:por_pagina] or 20))
  end

	# en proyectos y en financiación: establece los parametros de ordenación
  def ordenado
    session[:etiqueta_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC" 
    session[:etiqueta_orden] = params[:orden] ? params[:orden].gsub(".capitalize","") : "nombre" 
    redirect_to :action => "listado"
  end
  
	# en proyectos y en financiación: prepara el formulario de edición o creación
  def editar_nuevo
    @etiqueta = Etiqueta.find_by_id params[:id]
    render :partial => "formulario"
  end

	# en proyectos y en financiación:  modifica o crea
  def modificar_crear
    @etiqueta = Etiqueta.find_by_id(params[:id]) || Etiqueta.new
    @etiqueta.update_attributes params[:etiqueta]
    msg @etiqueta
    redirect_to :action => "listado"
  end    

	# en proyectos y en financiación: elimina documento
  def eliminar
    @etiqueta = Etiqueta.find_by_id params[:id]
    @etiqueta.destroy
    msg_eliminar @etiqueta
    redirect_to :action => 'listado'
  end

end
