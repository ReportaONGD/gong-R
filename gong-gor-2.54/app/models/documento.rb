# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2015 Free Software's Seed, CENATIC y IEPALA
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
# documento

class Documento < ActiveRecord::Base
  #untranslate_all
  # validates_presence_of :descripcion, :adjunto_filename

  # Auditado de modificaciones y comentarios
  include ::Auditable
  has_many :comentario, as: :elemento, dependent: :destroy

  has_many :etiqueta_x_documento, :dependent => :destroy
  has_many :etiqueta, :through => :etiqueta_x_documento, :uniq => true
  #has_and_belongs_to_many :etiqueta, :join_table => :etiqueta_x_documento
  belongs_to :proyecto
  belongs_to :agente
  #belongs_to :financiacion
  belongs_to :usuario
  #belongs_to :espacio
  has_many :documento_x_espacio, :dependent => :destroy
  has_many :espacio, :through => :documento_x_espacio

  # Vinculacion con transferencias
  has_many :transferencia_x_documento, :dependent => :destroy
  has_many :transferencia, :through => :transferencia_x_documento
  # Vinculacion con gastos 
  has_many :gasto_x_documento, :dependent => :destroy
  has_many :gasto, :through => :gasto_x_documento
  # Vinculacion con fuentes de verificacion
  has_many :fuente_verificacion_x_documento, :dependent => :destroy
  has_many :fuente_verificacion, :through => :fuente_verificacion_x_documento
  # Vinculacion con contratos
  has_many :contrato_x_documento, :dependent => :destroy
  has_many :estado_contrato, :through => :contrato_x_documento
  has_many :contrato, :through => :estado_contrato

  #validates_presence_of :espacio_id, :message => _("Espacio") + _(" no puede estar vacío.")

  # Guardar segun nos diga el environment
  # No usar nunca los nombres del archivo para las subidas!!!
  #has_attached_file :adjunto, :path => ENV["RAILS_VAR"] + "documento." + Digest::MD5.hexdigest(":basename :extension :id"),
  #has_attached_file :adjunto, :path => ":rails_root/documentos/:id/:basename.:extension",
  has_attached_file :adjunto, :path => ENV["RAILS_VAR"] + "documento.:id",
    :url => "descargar/:id"
  validates_attachment_presence :adjunto, :message => _("Tienes que subir por lo menos un documento")
  validates_presence_of :descripcion, :message => _("Descripción") + " " + _("no puede estar vacía.")

  def directory?
    return false
  end

  def ruta_espacio_original
    [espacio.first.ruta + " / " + espacio.first.nombre] unless espacio.empty?
  end

  def ruta_espacios_vinculados
    return espacio.collect{|m| m.ruta + " / " + m.nombre}[1..-1] unless espacio.empty? 
  end

  def etiquetas
    etiqueta.order("etiqueta.nombre").collect{|m| m.nombre}
  end

  # Guarda las modificaciones en las etiquetas de un documento
  def set_etiqueta_ids(ids=[])
    ids_activas = ids.select{|i| i[1] == "1"}.collect{|i| i[0]}
    # Borra las no activas
    (etiqueta_ids - ids_activas).each do |etiqueta_id|
      exd = EtiquetaXDocumento.find_by_etiqueta_id_and_documento_id(etiqueta_id, self.id)
      exd.destroy if exd 
      errors.add( :base, _("Error borrando etiqueta del documento") + ": " + exd.errors.inject('') {|total, e| total + e[1]} ) unless exd.nil? || exd.errors.empty?
    end
    # Y crea las activas
    self.etiqueta_ids = ids_activas if errors.empty?
  end

  # Autoriza tocar un documento dado en un espacio concreto
  def escritura_permitida usr, esp=espacio.first
    autorizado = true 
    # Si es un documento que existe y ( esta en un espacio y es el que nos indican )
    if (self.id && espacio.size > 0) && ( esp.escritura_permitida(usr) )
      # Permitimos modificar y borrar solo al propietario del documento y al coordinador.
      if usuario_id && usuario_id != usr.id
        # Si el documento esta en un espacio de proyecto, autoriza solo al moderador (ademas del propietario)
        if proj=esp.proyecto_del_espacio
          autorizado = proj.usuario_admin?(usr)
        end
      end
    else
      autorizado = false unless (self.id.nil? || espacio.empty?)
    end
    return autorizado
  end
end
