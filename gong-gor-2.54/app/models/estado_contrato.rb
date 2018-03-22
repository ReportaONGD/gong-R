# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2015 Free Software's Seed, CENATIC y IEPALA
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
# estado

class EstadoContrato < ActiveRecord::Base
  #untranslate_all
  belongs_to :workflow_contrato
  belongs_to :contrato
  belongs_to :usuario
  has_many :contrato_x_documento, dependent: :destroy
  has_many :documento, through: :contrato_x_documento
  has_many :etiqueta, through: :documento, order: :nombre

  validates_presence_of :contrato_id, message: _("Contrato") + " " + ("no puede estar vacío.")
  validates_presence_of :workflow_contrato_id, message: _("Estado") + " " + ("no puede estar vacío.")
  validates_presence_of :usuario_id, message: _("Usuario") + " " + ("no puede estar vacío.")

  # Comprobamos cambio de estado en contratos 
  validate :verificar_condiciones_estado, if: :estado_actual

  # Devuelve todos los documentos subidos
  def documento_nombre
    documento.order(:adjunto_file_name).collect{|d| d.adjunto_file_name}
  end

  # Devuelve todas las etiquetas subidas en este estado
  def etiqueta_nombre
    etiqueta.uniq.collect{|e| e.nombre}
  end

 private

  # Revisa las condiciones de cambio de los contratos
  def verificar_condiciones_estado
    # Obtenemos las etiquetas del estado anterior (aquel que aun esta como "estado_actual"
    estado_anterior = EstadoContrato.find_by_contrato_id_and_estado_actual(contrato_id, true)
    etiquetas_disponibles = estado_anterior ? estado_anterior.etiqueta : [] 
    # Analizamos que existan los documentos asociados a estas etiquetas en el estado previo
    etiquetas_ausentes = workflow_contrato.etiqueta(contrato.agente) - (estado_anterior ? estado_anterior.etiqueta : [])
    errors.add :base, _("No se han subido todos los documentos necesarios para entrar en este estado. Documentos pendientes: %s")%[etiquetas_ausentes.collect{|e| e.nombre}.join(", ")] unless etiquetas_ausentes.empty?
    
    # Solo permitimos cambio a "aprobado" cuando...
    if workflow_contrato.aprobado
      # si el contrato dispone de codigo
      errors.add :base, _("El contrato no dispone de código.") if contrato.codigo.blank?
      # Y si dispone de proveedor
      errors.add :base, _("El contrato no tiene asignado proveedor.") unless contrato.proveedor 
      # Y si tiene un tipo de contrato aceptado
      errors.add :base, _("El contrato no corresponde a ninún tipo de contrato definido.") unless contrato.tipo_contrato
      # Validamos condiciones particulares
      contrato.comprobar_condiciones_tipo_contrato
      contrato.errors.full_messages.each {|m| errors.add :base, m}
    end

    # y revisa las condiciones de cambio de los plugins (si las hubiera) 
    Plugin.activos.each do |plugin|
      begin
        eval(plugin.clase + "::EstadoContrato").verificar_condiciones_estado self
      rescue => ex
      end
    end
    return self.errors.empty?
  end

end
