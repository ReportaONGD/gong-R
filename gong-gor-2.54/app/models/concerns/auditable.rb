# encoding: UTF-8
#--
##
##################################################################################
## Copyright 2015/2016 Free Software's Seed / OEI 
#
# Licencia con arreglo a la EUPL, Versión 1.1 o –en cuanto sean aprobadas
# por la Comisión Europea- versiones posteriores de la EUPL (la «Licencia»);
# Solo podrá usarse esta obra si se respeta la Licencia.
# Puede obtenerse una copia de la Licencia en:
#
# http://www.osor.eu/eupl/european-union-public-licence-eupl-v.1.1
#
# Salvo cuando lo exija la legislación aplicable o se acuerde por escrito, 
# el programa distribuido con arreglo a la Licencia se distribuye «TAL CUAL»,
# SIN GARANTÍAS NI CONDICIONES DE NINGÚN TIPO, ni expresas ni implícitas.
# Véase la Licencia en el idioma concreto que rige los permisos y limitaciones
# que establece la Licencia.
##################################################################################
##
##++
#

# Mecanismos basicos de auditoria de elementos
# 1) Genera un registro "comentario" con los cambios, fecha y usuario
# 2) Marca el elemento
module Auditable
  extend ActiveSupport::Concern

  included do
    # Despues de guardar el elemento, generamos un comentario con las modificaciones del campo
    after_save :auditar_modificaciones
    after_destroy :auditar_borrados
  end

  # Callback "after_save" para auditar modificaciones
  def auditar_modificaciones
    # Obtenemos los cambios producidos excluyendo el marcado y el campo de fecha de modificacion
    cambios = self.changed
    cambios.delete("marcado_id") if self.respond_to?('marcado_id')
    cambios.delete("updated_at") if self.respond_to?('updated_at')
    # Si tenemos algun cambio a registrar lo hacemos
    auditar_elemento(elemento_auditado_relacionado, cambios) if cambios.size > 0
  end
  # Callback "after_destroy" para auditar borrados de elementos hijos
  def auditar_borrados
    # Solo tiene sentido meter comentarios o marcado si el elemento auditable no es el mismo objeto 
    elemento = elemento_auditado_relacionado
    auditar_elemento(elemento) if elemento != self
  end

 private

  # Genera las anotaciones sobre el elemento a auditar
  def auditar_elemento elemento, cambios=[]
    # Marcamos el elemento si esta asociado con el marcado
    auditar_genera_marcado(elemento) if elemento.respond_to?('marcado')
    # Generamos el comentario si lo ha invocado un usuario
    auditar_genera_comentario(elemento, cambios) if elemento.respond_to?('comentario')
  end

  # Devuelve los elementos auditados segun el tipo de objeto
  # De esta forma anotamos las modificaciones de objetos hijos en los objetos auditados
  def elemento_auditado_relacionado
    case self.class.name
      when "EstadoContrato" then self.contrato
      when "Pago" then self.gasto
      else self
    end
  end

  # Genera el marcado del elemento
  def auditar_genera_marcado elemento 
    # Si no se ha hecho una modificacion de marcado...
    # ... y esta definida una marca automatica
    if (elemento.marcado_id == elemento.marcado_id_was) && (marca_automatica = Marcado.find_by_automatico(true))
      # La modificacion la guarda evitando validaciones y callbacks
      elemento.update_column(:marcado_id, marca_automatica.id)
    end
  end

  # Genera un comentario en el elemento
  def auditar_genera_comentario elemento, cambios
    nombre_objeto = self.class.name.underscore.humanize
    usuario = UserInfo.current_user
    usuario_id = usuario ? usuario.id : nil
    # Si hacemos un destroy...
    if self.destroyed?
      texto = nombre_objeto + " " + _("eliminado")
    # Si lo estamos creando nuevo...
    elsif self.id_was.nil?
      texto = nombre_objeto + " " + _("creado")
    # Si lo estamos modificando, indicamos los campos modificados...
    else
      texto = nombre_objeto + " " + _("modificado") + " (" + _("campos") + ": " + cambios.join(", ") + ") "
    end
    comentario = ::Comentario.create usuario_id: usuario_id, texto: texto, sistema: true,
                                     elemento_type: elemento.class.name, elemento_id: elemento.id
    logger.error "========== ERROR en registro de cambios: " + comentario.errors.inspect unless comentario.errors.empty?
  end

end
