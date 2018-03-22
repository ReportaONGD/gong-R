#Transferencia(id: integer, importe: decimal, proyecto_id: integer, moneda_id: integer, libro_id: integer, libro_receptor_emisor_id: integer, agente_id: integer, observaciones: string, entrante_saliente: string, iban: string, tasa_cambio: decimal, fecha: date)
#  validates_presence_of :importe, :message => _("Importe") + _(" no pueden estar vacío.")
#  validates_presence_of :moneda_id, :message => _("Moneda") + _(" no pueden estar vacío.")
#  validates_presence_of :libro_id, :message => _("Cuenta") + _(" no pueden estar vacío.")
#  validates_presence_of :entrante_saliente, :message => _("Tipo") + _(" no pueden estar vacío.")
#  validates_presence_of :fecha,  :message => _("Fecha") + _(" no pueden estar vacío.")
Dado /^que hay 2 transferencias$/ do
  # Nota: Ojo usar el español aquí parece que no funciona
  steps %Q{
   Given "TRANSFERENCIA-01" es una transferencia con el importe "200.00" y con la fecha "27-09-2010" y con la moneda "Euro" y con el libro "LIBRO-01" y con el agente "AGENTE-01" y con entrante saliente "saliente"
   And "TRANSFERENCIA-02" es una transferencia con el importe "400.00" y con el libro "LIBRO-01" y con la fecha "30-09-2010" y con la moneda "Euro" y con el agente "AGENTE-01" y con entrante saliente "entrante"
  }
end

# (no existe proyecto en transferencia!) y con el proyecto "PROYECTO-01"
#  y con el proyecto "PROYECTO-01"


