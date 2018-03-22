# Agente(id: integer, nombre: string, nombre_completo: string, financiador: boolean, implementador: boolean)
# validates_uniqueness_of :nombre, :message => _("Nombre") +   _(" repetido.")
# validates_presence_of :nombre, :message => _("Nombre") + _(" no puede estar vacío.")

Dado /^que existe un agente por defecto$/ do
  steps %Q{
    Given "AGENTE-01" es un agente con el nombre "AGENTE-01" y el nombre completo "Nombre completo del agente 01" y no es un financiador y es un implementador
  }
end

