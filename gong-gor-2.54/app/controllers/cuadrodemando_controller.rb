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
# Controlador encargado de la visualización del cuadro de mando 

require 'net/http'

class CuadrodemandoController < ApplicationController

  protect_from_forgery :except => :index

  def index
    # Capturamos las excepciones que se produzcan aqui por si no esta instalado el modulo
    begin
      uri = ENV['GONG_CM_URL']? ENV['GONG_CM_URL'] : 'http://127.0.0.1:8080/' 
      url = URI.parse( uri )
      tipo_cm  = params[:menu]||"tecnico"
      prefix = 'cm_' + tipo_cm + ( ENV['GOR_SITEID'] ? "-" + ENV['GOR_SITEID'] : "")

      # Genera la cabecera a enviar
      headers = { "Referrer" => uri + "mondrian/testpage.jsp", "Cookie" => "JSESSIONID=" + cookies[:JSESSIONID] + " Path=/mondrian" } if cookies[:JSESSIONID]
      # Obtiene la pagina a pedir
      peticion = /\/cuadrodemando\/economico(.+)/.match(request.url) if params[:menu] == "economico"
      peticion = /\/cuadrodemando\/tecnico(.+)/.match(request.url) if params[:menu] == "tecnico"
      pagina = peticion ? peticion[1] : '?query=' + prefix 
      # Obtiene los parametros como un string
      unless request.request_parameters.empty?
        query_params = request.request_parameters.collect {|k,v| "#{k}=#{v}"} .join("&")
      end

      if request.get?
        # Hace la petición get
        #logger.info "---------------> " + request.inspect
        result = Net::HTTP.start(url.host, url.port) {|http|
           mondrian_params = request.fullpath.match(/^\/mondrian\/([^?]+)[?]+(.+)/)
           if mondrian_params
             #logger.info "---------------> Peticion Mondrian:" + mondrian_params[1]
             #logger.info "---------------> Parametros Mondrian: " + mondrian_params[2]
             http.send_request('GET', '/mondrian/' + mondrian_params[1], mondrian_params[2], headers)
           else
             http.send_request('GET', '/mondrian/testpage.jsp' + pagina, query_params, headers)                                             
           end
        }
      elsif request.post?
        # Hace la petición post 
        result = Net::HTTP.start(url.host, url.port) {|http|
          http.send_request('POST', '/mondrian/testpage.jsp',query_params, headers)
        }
      end

      # Guarda la cookie de la sesión para utilizarla en la navegacion de mondrian
      result.get_fields('set-cookie').each do |cookie|
        cookie_valor = cookie.sub(/JSESSIONID=(\w+);\sPath=\/mondrian/, '\1')
        cookies[:JSESSIONID] = { :value => cookie_valor } if cookie_valor
      end if result.get_fields('set-cookie')

      # Reescritura de URLs
      @cuadrodemando = result.body

      # Parsea el codigo devuelto para cambiar las URLs
      @cuadrodemando = @cuadrodemando.gsub(/href="testpage.jsp/, 'href="/cuadrodemando/' + tipo_cm + '/mondrian/testpage.jsp')
      @cuadrodemando = @cuadrodemando.gsub(/action="testpage.jsp"/, 'action="/cuadrodemando/' + tipo_cm + '"')
      @cuadrodemando = @cuadrodemando.gsub(/href="\/mondrian/, 'href="/cuadrodemando/' + tipo_cm + '/mondrian')
      # Imagenes y elementos estaticos, que se pidan directamente al mondrian via un proxy apache
      @cuadrodemando = @cuadrodemando.gsub(/src="([\/])mondrian/, 'src="/mondrian')
      @cuadrodemando = @cuadrodemando.gsub(/href="jpivot/, 'href="/mondrian/jpivot')
      @cuadrodemando = @cuadrodemando.gsub(/href="wcf/, 'href="/mondrian/wcf')
      @cuadrodemando = @cuadrodemando.gsub(/href="\.\/Print/, 'href="/mondrian/Print')
      @cuadrodemando.force_encoding("UTF-8")
    rescue
      msg_error _("Se produjo un error en el módulo de CuadroDeMando. Contacte con el administrador del sistema.")
    end
  end
end
