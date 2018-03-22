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
class Libro < ActiveRecord::Base

  before_destroy :verificar_borrado

  belongs_to :agente
  belongs_to :moneda
  belongs_to :pais

  has_many :libro_x_proyecto, :dependent => :destroy
  has_many :proyecto, :through => :libro_x_proyecto
  #has_many :gasto, :dependent => :nullify
  has_many :pago, :dependent => :nullify
  has_many :presupuesto, :dependent => :nullify
  has_many :usuario_x_libro, :dependent => :destroy
  has_many :usuario, :through => :usuario_x_libro
  has_many :grupo_usuario_x_libro, :dependent => :destroy
  has_many :grupo_usuario, :through => :grupo_usuario_x_libro, :order => :nombre
  #has_many :transferencia
  has_many :transferencia_enviado, :class_name => "Transferencia", :foreign_key => :libro_origen_id
  has_many :transferencia_recibido, :class_name => "Transferencia", :foreign_key => :libro_destino_id

  # Codigo de contabilidad (hay uno por cada delegacion)
  # Es cierto que hay uno por delegacion???... Si el libro no es de la delegacion no deberia estar en contabilidad
  has_many :cuenta_contable, :as => :elemento_contable, :dependent => :destroy

  validate :nombre_mayusculas
  validates_presence_of :nombre, :message => _("Nombre") + " " + _("no puede estar vacío.")
  validates_presence_of :agente_id, :message => _("Agente") + " " + _("no puede estar vacío.")
  validates_presence_of :moneda_id, :message => _("Moneda") + " " + _("no puede estar vacía.")
  validates_presence_of :pais_id, :message => _("País") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :nombre, :message => _("Nombre repetido."), :case_sensitive => false

  def nombre_mayusculas
    self.nombre = self.nombre.upcase
  end

  # Devuelve el nombre (esto es necesario para hacer comunes los helpers en el listado de subcuentas)
  def codigo_nombre
    return self.nombre
  end

  # actualiza los usuario del libro (utilizado por LibroController::guardar_usuarios )
  def actualizar_usuario_x_libro listado
    usuario_x_libro.clear
    listado.each do |key, value|
        uxp = usuario_x_libro.create(value)
        errors.add("", uxp.errors.inject('') {|total, e| total + e[1] + "<br>" }) unless uxp.errors.empty?
    end        
  end

        # Devuelve si el usuario gestiona o no el agente 
  def usuario_autorizado? user=nil
    obj = usuario_x_libro.find_by_usuario_id(user.id) if user && user.class.name == "Usuario"
    return obj ? true : false
  end

	# Devuelve los usuarios_x vinculados directamente (no a traves de grupo)
  def usuario_x_vinculado
    return usuario_x_libro.where(:grupo_usuario_id => nil)
  end

  def verificar_borrado
    errors.add( "pago", _("hay pagos asociados")) unless self.pago.empty?
    errors.add( "transferencia", _("hay transferencias asociadas")) unless self.transferencia_enviado.empty? && self.transferencia_recibido.empty?
    errors.add( "proyecto", _("Hay proyectos con esta cuenta definida como principal")) if Proyecto.find_by_libro_id(self.id)
    errors[:base] << ( _("Una cuenta tiene que estar vacía para poder ser borrada.") ) unless errors.empty?
    return false unless errors.empty?
 end

	# Hace un arqueo de la cuenta para los proyectos referidos
 def arqueo proy=[], fecha_inicio=nil, fecha_fin=nil, financiador=nil
   # Inicializa las variables de salida
   filas_desglosado = Array.new
   total = Hash.new
   entrante=0
   saliente=0

   # Establece los datos para buscar las transferencias enviadas 
   condiciones = Hash.new 
   condiciones[:fecha_enviado] = fecha_inicio..fecha_fin if fecha_inicio && fecha_fin
   condiciones[:proyecto_id] = proy.collect{|p| p.id } unless proy.empty?
   # Si nos mandan financiador, lo incluimos (util para remanentes)
   condiciones["transferencia_x_agente.agente_id"] = financiador.id if financiador
   transferencias = self.transferencia_enviado.all(:include => ['transferencia_x_agente'], :conditions => condiciones)
  
   # Recorre y toma todos los datos de las transferencias enviadas
   transferencias.each do |transferencia|
     if ( transferencia.tipo != "remanente" || proy.size == 1 ) && transferencia.importe_enviado && transferencia.fecha_enviado
       total[transferencia.tipo.capitalize] = Hash.new if total[transferencia.tipo.capitalize].nil?
       total[transferencia.tipo.capitalize]["Saliente"] ||= 0
       total[transferencia.tipo.capitalize]["Saliente"] += transferencia.importe_enviado
       saliente += transferencia.importe_enviado
       filas_desglosado.push( :contenido => [  transferencia.fecha_enviado, _(transferencia.tipo.capitalize), transferencia.observaciones ? transferencia.observaciones : '',
                                               '', transferencia.importe_enviado ],
                              :objeto_tipo => "transferencia", :objeto_id => transferencia.id, :objeto_campos => "transferencia" )
     end
   end

   # Establece los datos para buscar las transferencias entrantes 
   condiciones = Hash.new
   condiciones[:fecha_recibido] = fecha_inicio..fecha_fin if fecha_inicio && fecha_fin
   condiciones[:proyecto_id] = proy.collect{|p| p.id } unless proy.empty?
   # Si nos mandan financiador, lo incluimos (util para remanentes)
   condiciones["transferencia_x_agente.agente_id"] = financiador.id if financiador
   transferencias = self.transferencia_recibido.all(:include => ['transferencia_x_agente'], :conditions => condiciones)

   # Recorre y toma todos los datos de las transferencias
   transferencias.each do |transferencia|
     if ( transferencia.tipo != "remanente" || proy.size <= 1 ) && transferencia.importe_cambiado && transferencia.fecha_recibido
       total[transferencia.tipo.capitalize] = Hash.new if total[transferencia.tipo.capitalize].nil?
       total[transferencia.tipo.capitalize]["Entrante"] ||= 0
       total[transferencia.tipo.capitalize]["Entrante"] += transferencia.importe_cambiado
       entrante += transferencia.importe_cambiado 
       filas_desglosado.push( :contenido => [  transferencia.fecha_recibido, _(transferencia.tipo.capitalize), transferencia.observaciones ? transferencia.observaciones : '',
                                               transferencia.importe_cambiado, '' ],
                              :objeto_tipo => "transferencia", :objeto_id => transferencia.id, :objeto_campos => "transferencia" )
     end
   end

 
   # Establece las condiciones para buscar los gastos relevantes
   condiciones = Hash.new
   condiciones["pago.fecha"] = fecha_inicio..fecha_fin if fecha_inicio && fecha_fin
   condiciones["pago.libro_id"] = self.id
   gastos = proy.each.collect {|p| p.gasto.all(:include => ["pago"], :conditions => condiciones)}.flatten unless proy.empty?
   gastos = Gasto.all(:include => ["pago"], :conditions => condiciones) if proy.empty?

   # Recorre y toma todos los datos de los pagos
   gastos.each do |gasto|
     gasto.pago.each do |pago|
       total["Pago"] = Hash.new if total["Pago"].nil?
       total["Pago"]["Saliente"] = 0 if total["Pago"]["Saliente"].nil?
       # Indica si el gasto no está totalmente pagado
       # Si no es por proyecto (es para un agente), pilla los datos del pago
       if proy.empty?
         total["Pago"]["Saliente"] += pago.importe
         saliente += pago.importe
         filas_desglosado.push( :contenido => [      pago.fecha, _("Pago"), (pago.observaciones||gasto.concepto),
                                                       '', pago.importe ],
                                :objeto_tipo => "gasto", :objeto_id => gasto.id, :objeto_campos => "gasto_agentes", :html_id => pago.id )
       # Si es por proyectos, los recorre para coger solo el importe asociado a cada uno
       else
         proy.each do |p|
           # ... obtiene el gasto del proyecto si no se ha pedido por financiador
           importe_gasto = gasto.importe_x_proyecto_financiador(Proyecto.find_by_id(p), financiador)
           if (importe_gasto)
             # ... coge el equivalente al porcentaje
             
             unless financiador
               importe = pago.importe * importe_gasto / gasto.importe 
               # Evitamos valores raros si gasto.importe es igual a 0 (caso excepcional de estar registrando pagos todavia sin factura)
               if gasto.importe == 0
                 if gasto.proyecto_origen_id
                   # Si el gasto viene de un proyecto ponemos el valor del pago
                   importe = pago.importe 
                 else
                   # Si el gasto viene de delegación calculamos el total de lo asignado a proyectos y prorrateamos el pago
                   total_importes_gasto = gasto.gasto_x_proyecto.inject (0) {|suma, gxp| suma + gxp.importe }
                   importe = pago.importe * importe_gasto / total_importes_gasto unless total_importes_gasto == 0
                   # Si el importe del total es 0 ponemos 0
                   importe = 0 if total_importes_gasto == 0
                 end
               end
             end
             
             importe = importe_gasto if financiador
             total["Pago"]["Saliente"] += importe
             saliente += importe
             filas_desglosado.push( :contenido => [	pago.fecha, _("Pago"), (pago.observaciones||gasto.concepto),
							'', importe ],
							:objeto_tipo => "gasto", :objeto_id => gasto.id, :objeto_campos => "gasto", :html_id => pago.id )
           end
         end
       end
     end
   end

   # Ordena por fecha
   filas_desglosado.sort! { |x,y| x[:contenido][0] <=> y[:contenido][0] }

   return {:filas => filas_desglosado, :totales => total, :entrante => entrante, :saliente => saliente}
 end

end
