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


class DatosAgenteController < ApplicationController

 # --
 ########## ETAPAS ##########
 # ++
	# en agentes: se redirecciona por defecto a etapas
  def index
    redirect_to :action => 'etapas'  
  end

  # en agentes: lista las etapas relacionadas
  def etapas
    @etapas = @agente.etapa
    render "comunes/etapas"
  end

  #  en agentes: crea una nueva etapa con un tipo determinado según la sección.
  def editar_nuevo_etapa
    @etapa = params[:id] ?  Etapa.find(params[:id]) : nil
    render :partial => "comunes/etapa"
  end

	#  en agentes: modifica o crea un determinada etapa
  def modificar_crear_etapa
    @etapa = params[:id] ?  Etapa.find(params[:id]) : Etapa.new(:agente_id => @agente.id)
    @etapa.update_attributes params[:etapa]
    msg @etapa
    redirect_to :action => 'etapas'
  end

	#  en agentes: elimina etapa.
  def eliminar_etapa
    @etapa = Etapa.find(params[:id])
    @etapa.destroy
    msg_eliminar @etapa
    redirect_to :action => 'etapas'
  end


 # --
 ########## REMANENTE DE UNA ETAPA ##########
 # ++

  def calcula_resumen_remanentes
    @resumen = Hash.new
    if @etapa
      remanente = @agente.remanente(@etapa)
      lineas = Array.new
      for libro_id in remanente.keys
        l=Libro.find_by_id(libro_id)
        transf = Transferencia.first(:conditions=>{:proyecto_id => nil, :libro_destino_id => libro_id, :remanente => true, :fecha_recibido => @etapa.etapa_siguiente.fecha_inicio})
        saldo = remanente[libro_id][:entrante] - remanente[libro_id][:saliente]
        if l && ( saldo != 0 || transf )
          lineas.push( :cabecera => [ ["","3_2"], [_("Entradas"),"1_2_td"], [_("Salidas"),"1_2_td"], [_("Saldo"),"1_2_td"], ['',"1_2"], [_("Remanente Aplicado"),"2_3_td" ] ])
          lineas.push( :cabecera => [ [l.nombre + " (" + l.moneda.nombre + ")","3_2"], [remanente[libro_id][:entrante],"1_2_td"], [remanente[libro_id][:saliente],"1_2_td"], [saldo,"1_2_td"], ['',"1_2"], [(transf ? transf.importe_recibido : 0),"2_3_td"] ])
          #remanente[libro_id][:totales].each do |k,v|
          #  lineas.push( :contenido => [ '',k,v["Entrante"]||'',v["Saliente"]||'','' ] )
          #end
          lineas.push( :contenido => [ '','','','','' ] )
        end
      end
      @resumen = Hash.new
      if lineas.size > 0
        @resumen[:listado] = {:nombre => "remanentes", :titulo => _("Remanentes de la Etapa"), :lineas => lineas}
      end
    end
  end

	# En agentes: muestra los remanentes sobrantes en la etapa
  def mostrar_remanente
    @etapa = Etapa.find_by_id(params[:id])
    calcula_resumen_remanentes
    render(:update) { |page| page.replace_html params[:update], :partial => "remanente" }
  end

	# En agentes: aplica los remanentes sobrantes en la etapa
  def generar_remanente
    @etapa = Etapa.find_by_id(params[:id])
    @agente.generar_remanente @etapa
    if @agente.errors.empty?
      @etapas = @agente.etapa
      render(:update) do |page|
        page.actualizar :update_listado => "etapas", :partial => "comunes/etapas", :mensaje => { :errors => @agente.errors }
      end
    else
      calcula_resumen_remanentes
      render(:update) do |page|
        page.actualizar :update_listado => params[:update], :partial => "remanente", :mensaje => { :errors => @agente.errors }
      end
    end
  end

  def ordenado
    session[:datos_agente_orden] = params[:orden] ? params[:orden] : "nombre"
    session[:datos_agente_asc_desc] = params[:asc_desc] ? params[:asc_desc] : "ASC"
    redirect_to action: params[:listado]
  end

 # --
 ########## MONEDAS ##########
 # ++

  # en agentes: lista las monedas relacionadas
  def monedas
    @monedas = @agente.moneda.order((session[:datos_agente_orden]||"nombre") + " " + (session[:datos_agente_asc_desc]||"ASC")).reload
  end

  #  en agentes: crea o edita una nueva moneda
  def editar_nuevo_moneda
    monedas_agente = @agente.moneda
    monedas_todas = Moneda.find(:all)
    @monedas = (monedas_todas - monedas_agente).collect {|m| [m.nombre, m.id]}
    render :partial => "moneda"
  end

	#  en agentes: modifica o crea un determinada moneda 
  def modificar_crear_moneda
    axm = AgenteXMoneda.create(:agente_id => @agente.id, :moneda_id => params[:moneda][:relacionada]) unless params[:moneda].nil? or params[:moneda][:relacionada] == ""
    msg_error _("Debe elegir una moneda para relacionarla con el agente") if params[:moneda].nil? or params[:moneda][:relacionada] == ""
    msg(axm) unless params[:moneda].nil? or params[:moneda][:relacionada] == ""
    redirect_to :action => 'monedas'
  end

	#  en agentes: elimina moneda.
  def eliminar_moneda
    axm = @agente.agente_x_moneda.find_by_moneda_id(params[:id])
    axm.destroy if axm
    msg_eliminar axm if axm
    redirect_to :action => 'monedas'
  end

end
#done

