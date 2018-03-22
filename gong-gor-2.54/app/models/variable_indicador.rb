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
class VariableIndicador < ActiveRecord::Base
  #untranslate_all
  belongs_to :indicador
  belongs_to :valor_base, :foreign_key => "valor_base_id", :class_name => "ValorVariableIndicador", :dependent => :destroy
  belongs_to :valor_objetivo, :foreign_key => "valor_objetivo_id", :class_name => "ValorVariableIndicador", :dependent => :destroy
  has_many :valor_medido, :foreign_key => "variable_indicador_id", :class_name => "ValorVariableIndicador", :dependent => :destroy

  def ultimo_valor
    valor_medido.find(:all,:order => "fecha").last
  end

  # Metodo creado para el WS de matriz.
  # Indica el estado de la variable de indicador en cada periodo de justificacion 
  def estado_seguimiento fecha_max=nil
    resultado = []

    # Para los PACs y convenios, busca agrupado por etapas
    if (indicador.proyecto.convenio_id || indicador.proyecto.convenio?)
      cond_etap = fecha_max ? ["fecha_fin <= ?", fecha_max] : nil
      indicador.proyecto.etapa.where(cond_etap).each do |periodo|
        estado = self.valor_medido.where(["fecha <= ?", periodo.fecha_fin]).order("fecha asc").last
        resultado.push({:nombre => periodo.nombre, :estado => {:fecha => estado.fecha, :valor => estado.valor, :comentario => estado.comentario}}) if estado
      end
    # Para los proyectos, muestra segun los periodos de justificacion
    else
      indicador.proyecto.periodo_justificacion.each do |periodo|
        estado = self.valor_medido.where(["fecha <= ?", periodo.fecha_inicio]).order("fecha asc").last
        resultado.push({:seguimiento_periodo_id => periodo.id, :estado => {:fecha => estado.fecha, :valor => estado.valor, :comentario => estado.comentario}}) if estado
      end
    end

    return resultado
  end

end
