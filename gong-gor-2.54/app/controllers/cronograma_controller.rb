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
# Controlador encargado de la gestión de la matriz. Este controlador es utilizado desde las secciones:
# * Sección proyectos: se utiliza para los objetivos especificos, resultados, actividades...

class CronogramaController < ApplicationController
  
  before_filter :verificar_estado_no_cerrado_ajax, :only => [ :modificar_mes_cronograma, :modificar_abrir_cerrar_actividad, :modificar_abrir_cerrar_subactividad ]

  # Comprueba que no este cerrado
  def verificar_estado_no_cerrado_ajax
    unless @permitir_formulacion || @permitir_ejecucion
      render :update do |page|
        mensaje = 'El proyecto se encuentra sin estado. En este estado no se puede modificar el cronograma.'  if @proyecto.estado_actual.nil?
        mensaje = 'El proyecto no se encuentra en un estado adecuado para modificar el cronograma.' unless @proyecto.estado_actual.nil?
        page.mensaje_informacion params[:update], mensaje, :tipo_mensaje => "mensajefallo"
      end
    end
  end

  #--
  # CRONOGRAMA
  #++

  # Cronograma de actividades
  def listado 
    @etapas = @proyecto.etapa.reorder(:fecha_inicio).collect{|e| [e.nombre, e.id]}
    params[:selector] ||= {:etapa => @proyecto.etapa.first } if @proyecto.etapa.count == 1
    if params[:selector]
      @etapa = Etapa.find_by_id(params[:selector][:etapa])
      # Primero incluimos las actividades asociadas a resultados y luego las generales
      @actividades  = @etapa.actividad.where("resultado_id IS NOT NULL")
      # y luego las actividades globales
      @actividades += @etapa.actividad.where(resultado_id: nil)

      respond_to do |format|
        format.html 
        format.xls do
          nom_fich = "cronograma_" + params[:menu] + "_" + @proyecto.nombre.gsub(' ','_') + "_" + Time.now.strftime("%Y-%m-%d")
          render 'comunes_xls/cronograma', :xls => nom_fich, :layout => false
        end 
      end
    end
  end

  # Activa/desactiva el mes de la etapa para la actividad elegida
  def modificar_mes_cronograma
    seguimiento = params[:menu] == "ejecucion_tecnica"

    # Obtenemos el objeto de ese mes
    if params[:tipo] == "actividad"
      objeto = ActividadDetallada.find_by_mes(params[:mes], :conditions => { :etapa_id => params[:etapa_id], :actividad_id => params[:objeto_id], :seguimiento => seguimiento })
    else
      objeto = SubactividadDetallada.find_by_mes(params[:mes], :conditions => { :etapa_id => params[:etapa_id], :subactividad_id => params[:objeto_id], :seguimiento => seguimiento })
    end

    # Modificamos el estado del objeto en ese mes
    if objeto 
     objeto.destroy 
    else
     ActividadDetallada.new(:mes => params[:mes], :etapa_id => params[:etapa_id], :actividad_id => params[:objeto_id], :seguimiento => seguimiento).save if params[:tipo] == "actividad"
     SubactividadDetallada.new(:mes => params[:mes], :etapa_id => params[:etapa_id], :subactividad_id => params[:objeto_id], :seguimiento => seguimiento).save if params
[:tipo] == "subactividad"
    end

    # Obtenemos de nuevo los estados
    if params[:tipo] == "actividad"
      formulado = ActividadDetallada.find_by_mes(params[:mes], :conditions => { :etapa_id => params[:etapa_id], :actividad_id => params[:objeto_id], :seguimiento => false}) ? true : false
      ejecutado = ActividadDetallada.find_by_mes(params[:mes], :conditions => { :etapa_id => params[:etapa_id], :actividad_id => params[:objeto_id], :seguimiento => true}) ? true : false
    else
      formulado = SubactividadDetallada.find_by_mes(params[:mes], :conditions => { :etapa_id => params[:etapa_id], :subactividad_id => params[:objeto_id], :seguimiento => false}) ? true : false
      ejecutado = SubactividadDetallada.find_by_mes(params[:mes], :conditions => { :etapa_id => params[:etapa_id], :subactividad_id => params[:objeto_id], :seguimiento => true}) ? true : false
    end

    # Pintamos
    render :update do |page|
      page.replace params[:update], :partial => "mes_cronograma", :locals => { :update => params[:update], :seguimiento => seguimiento, :formulado => formulado, :ejecutado => ejecutado, :mes => params[:mes], :objeto_id => params[:objeto_id], :tipo => params[:tipo], :etapa_id => params[:etapa_id], :clickable => true }
    end
  end


  #--
  # ACTIVIDADES
  #++

  # Abre/Cierra la actividad
  def modificar_abrir_cerrar_actividad
    axe = ActividadXEtapa.find_by_actividad_id_and_etapa_id(params[:actividad_id], params[:etapa_id])
    axe.update_attribute :realizada, !axe.realizada
    render :update do |page|
      page.actualizar :update => params[:update], :partial => "actividad", :locals => { :actividad => axe.actividad, :etapa => axe.etapa }
      page.call('new Tooltip', params[:update] + '_etiqueta')
    end
  end


  #--
  # SUBACTIVIDADES
  #++

  # Abre/Cierra la subactividad
  def estado_subactividad
    @subactividad = Subactividad.find_by_id(params[:id]) || Subactividad.new
    render(:update) { |page| page.formulario(:partial => "formulario_subactividad", :update => params[:update])}
  end

  # Abre/Cierra la subactividad
  def modificar_abrir_cerrar_subactividad
    actividad = Actividad.find_by_id params[:actividad_id]
    etapa = Etapa.find_by_id params[:etapa_id]
    @subactividad = Subactividad.find_by_id(params[:id]) || Subactividad.new(:actividad_id => (actividad ? actividad.id : nil))
    @subactividad.update_attributes params[:subactividad]
    render(:update) do |page|
      page.modificar :update => params[:update], :partial => "subactividad", :locals => { :etapa => etapa, :actividad => actividad, :subactividad => @subactividad }
      page.call('new Tooltip', params[:update] + '_etiqueta')
    end if @subactividad.errors.empty?
    render(:update){ |page|  page.recargar_formulario :partial => "formulario_subactividad", :mensaje => { :errors => @subactividad.errors } } unless @subactividad.errors.empty?
  end

end


