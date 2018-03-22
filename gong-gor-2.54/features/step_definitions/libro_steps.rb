# Libro(id: integer, nombre: string, moneda_id: integer, agente_id: integer, cuenta: string, descripcion: string, tipo: string, pais_id: integer, iban: string, swift: string)
#   validates_presence_of :nombre, :message => _("Nombre") + _(" no pueden estar vacío.")
#   validates_presence_of :agente_id, :message => _("Agente") + _(" no pueden estar vacío.")
#   validates_presence_of :moneda_id, :message => _("Moneda") + _(" no pueden estar vacío.")
#   validates_presence_of :pais_id, :message => _("Pais") + _(" no pueden estar vacío.")
#   validates_uniqueness_of :nombre, :message => _("Nombre") +   _(" repetido.")

Dado /^dado un libro por defecto$/ do
  # Nota: Ojo usar el español aquí parece que no funciona
  steps %Q{
   Given que existe un proyecto por defecto
   And que existe un agente por defecto
   And "LIBRO-01" es un libro con el nombre "LIBRO-01" y con el agente "AGENTE-01" y con la moneda "Euro" y con la cuenta "Cuenta 01" y con el tipo "banco" y con el pais "Mozambique"
  }
  # y con la moneda "Euro" y con la cuenta "Cuenta 01" y con el tipo "banco" y con el pais "Mozambique"
end
