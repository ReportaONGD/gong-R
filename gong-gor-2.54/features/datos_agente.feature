Caracteristica: El administrador financiero de una delegación (u otro tipo de agente implementador) accede a la gestión del presupuesto de la delegación, y gestiona relaciona monedas con el agente con el objetivo de que sean las monedas habilitadas para la gestión económica del agente (gastos, presupuestos).

Antecendentes:
Dado un usuario con permisos para gestionar un agentes,
Y habiendo seleccionado el agente para el que tiene permisos,
Y estando en "datos del agente"
Y dentro de "datos de agente" en "Monedas relacionadas"

Escenario "añadir monedas"
Cuando doy a "añadir moneda relacionada"
Y relleno los datos de la moneda relacionad
Y doy a guardar.
Entonces en el listado de monedas se añade un nueva linea.

Escenario "borrar una moneda"
Y teniendo una linea de moneda,
Cuando pulso en borrar "moneda relacionada"
Y confirmo en la ventana de borrado
Entonces se borra una linea del listado de monedas.

