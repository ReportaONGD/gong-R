Caracteristica: El administrador financiero de una delegación (u otro tipo de agente implementador) accede a la gestión del presupuesto de la delegación, y gestiona (alta, modificación y borrado) las lineas de presupuesto para la etapa seleccionada, con el objetivo de poder aplicar las tasas al presupuesto y compararlo el presupuesto para la delegación para la etapa (año) seleccionada.
(Se utiliza el termino delegacion pero la funcionalidad es para agentes implementadores en general).

Escenario: Dado un usuario con permisos para gestionar un agentes,
Y habiendo seleccionado el agente para el que tiene permisos,
Y estando en la gestion del tasas de cambio del agente
Y habiendo seleccionado la gestion del presupuesto para una etapa.
Cuando doy a "Aplicar tasas de cambio al presupuesto"
Y relleno los datos de las tasas de cambio para cada moneda
Entonces el listado de presupuesto el campo "Importe x TC" tiene un valor distinto de cero.

