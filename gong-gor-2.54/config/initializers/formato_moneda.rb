ActiveRecord::Base.class_eval do

  # Esto es para poder usar el number_with_delimiter
  include ActionView::Helpers::NumberHelper

  def importe_convertido=(cadena)
    self.importe = moneda_a_float(cadena)
  end

  def importe_convertido
    float_a_moneda(importe)
  end

  def importe_convertido_texto
    # Incluimos la abreviatura de moneda si el modelo la tiene
    mon = self.respond_to?(:moneda) && self.moneda ? self.moneda.abreviatura : ""
    # Tenemos que hacer este lio por un bug en el plugin sin resolver: https://github.com/kslazarev/numbers_and_words/issues/107
    importe.to_i.to_words + " " + mon + ( importe.to_s.split(".")[1].to_i > 0 ? " " + _("con") + " " + importe.to_s.split(".")[1].to_i.to_words : "")
  end

  def importe_desconvertido cadena
    moneda_a_float(cadena)
  end

  def importe_enviado_convertido
    float_a_moneda(importe_enviado)
  end
  def importe_enviado_convertido=(cadena)
    self.importe_enviado = moneda_a_float(cadena)
  end
  def importe_recibido_convertido
    float_a_moneda(importe_recibido)
  end
  def importe_recibido_convertido=(cadena)
    self.importe_recibido = moneda_a_float(cadena)
  end
  def importe_cambiado_convertido
    float_a_moneda(importe_cambiado)
  end
  def importe_cambiado_convertido=(cadena)
    self.importe_cambiado = moneda_a_float(cadena)
  end

  def coste_unitario_convertido=(cadena)
    self.coste_unitario = moneda_a_float(cadena)
  end

  def coste_unitario_convertido
    float_a_moneda(coste_unitario)
  end

  def impuestos_convertido=(cadena)
    self.impuestos = moneda_a_float(cadena)
  end

  def importe_previsto_total_convertido
    float_a_moneda(importe_previsto_total)
  end

  def importe_previsto_total_convertido=(cadena)
    self.importe_previsto_total = moneda_a_float(cadena)
  end

  def importe_previsto_subvencion_convertido
    float_a_moneda(importe_previsto_subvencion)
  end

  def importe_previsto_subvencion_convertido=(cadena)
    self.importe_previsto_subvencion = moneda_a_float(cadena)
  end

  def impuestos_convertido
    float_a_moneda(impuestos)
  end

  def tasa_cambio_convertida=(numero)
    if numero 
      numero = numero.sub(/,/,".") if numero =~ /[\d]+,[\d]{1,9}$/
      self.tasa_cambio = numero.to_f
    end
  end

  def tasa_cambio_convertida
    tasa_cambio
  end

  def porcentaje_convertido=(numero)
    if numero
      numero = numero.sub(/,/,".") if numero =~ /[\d]+,[\d]{1,9}$/
      self.porcentaje = numero.to_f / 100.0
    end
  end

  def porcentaje_convertido
    porcentaje ? porcentaje * 100.0 : nil
  end

  def porcentaje_maximo_convertido=(numero)
    if numero
      numero = numero.sub(/,/,".") if numero =~ /[\d]+,[\d]{1,9}$/
      self.porcentaje_maximo = numero.to_f / 100.0
    end 
  end

  def porcentaje_maximo_convertido
    porcentaje_maximo && porcentaje_maximo != 0 ? porcentaje_maximo * 100.0 : nil 
  end

  private
    def float_a_moneda numero
      #('%.2f' % numero).to_s.sub(".",",") if numero
      number_with_delimiter(('%.2f' % numero).to_s , :separator => ",", :delimiter => ".") if numero
    end

    def moneda_a_float cadena
      if cadena
        # Eliminamos espacios antes y despues
        cadena.to_s.strip!
        # primero comprobamos que el punto corresponde a miles ( formato => n.nnn )
        # y solo en ese caso lo eliminamos => Permitimos especificar decimales con punto
        numero = (cadena =~ /[\d]+\.[\d]{3}/) ? cadena.delete(".") : cadena 
        # Si se esta usando la coma decimal, la cambiamos por un punto ( formato => n,nn o n,n )
        # REVISAR: Esto permite que haya coma para miles, pero impide que metan mas de 2 decimales con coma
        numero = numero.sub(/,/,".") if numero =~ /[\d]+,[\d]{1,2}$/
        return numero.to_f
      end
    end

end
