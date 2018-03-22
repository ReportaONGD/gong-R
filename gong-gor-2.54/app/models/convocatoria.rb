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

class Convocatoria < ActiveRecord::Base

  before_destroy :verificar_borrado

  validate :mayusculas
  validates_uniqueness_of :codigo, :message => _("Codigo repetido."), :case_sensitive => false
  validates_uniqueness_of :nombre, :message => _("Nombre repetido."), :case_sensitive => false
  validates_presence_of :codigo, :message => _("Codigo") + " " + _("no puede estar vacío.")
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :agente, :message => _("Financiador") + " " + _("no puede estar vacío.")

  belongs_to :agente
  belongs_to :tipo_convocatoria
  has_many :proyecto
  has_many :convocatoria_x_pais, :dependent => :destroy
  has_many :pais, :through => :convocatoria_x_pais

  # Codigo de contabilidad (hay uno por cada delegacion)
  has_many :cuenta_contable, :as => :elemento_contable, :dependent => :destroy

  # Actualiza un listado de paises vinculados a la convocatoria 
  def actualizar_paises listado
    paises_existentes = self.convocatoria_x_pais.collect {|cxp| {:convocatoria_id => self.id, :pais_id => cxp.pais_id} }
    paises_enviados = [] 
    # Limpia el listado de paises
    listado.each do |key, value|
      paises_enviados.push( {:convocatoria_id => self.id, :pais_id => value[:pais_id].to_i} ) unless value[:pais_id] == ""
    end
    paises_enviados.uniq!
    # Elimina los existentes que no esten en el listado
    (paises_existentes - paises_enviados).each do |cxp|
      conv = ConvocatoriaXPais.where(cxp).first
      # Borra verificando si vamos a dejar algun pais
      unless paises_enviados.empty?
        self.errors.add(:base, conv.errors.messages[:base].first) unless conv.destroy
      else
        conv.delete
      end
    end
    # Incluye los que falten por meter
    (paises_enviados - paises_existentes).each { |cxp| ConvocatoriaXPais.create(cxp) } if self.errors.empty?
    return self.errors.empty?
  end

  # Devuelve un listado de paises, o Global si no los hay
  def paises
    pais.count == 0 ? _("Ámbito Global") : pais.collect{|p| p.nombre}.join(", ") 
  end

  # Devuelve el nombre (esto es necesario para hacer comunes los helpers en el listado de subcuentas)
  def codigo_nombre
    return self.nombre
  end

 private
 
  def mayusculas
    self.codigo = self.codigo.upcase if self.codigo
    self.nombre = self.nombre.upcase if self.nombre
  end

  def verificar_borrado
    errors.add( "proyecto",_("hay proyectos")) unless self.proyecto.empty?
    errors[:base] << ( _("Una convocatoria tiene que estar vacía para poder ser borrada.") ) unless errors.empty?
    return errors.empty?
 end

end
