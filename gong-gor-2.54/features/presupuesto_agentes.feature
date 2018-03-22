
Característica: El administrador financiero de una delegacion (u otro tipo de agente implementador) accede a la gestion del presupuesto de la delegacion, y gestiona (alta, modificacion y borrado) las lineas de presupuesto para la etapa seleccionada, con el objetivo de poder elaborar el presupuesto para la delegacion para la etapa (año) seleccionada.

Antecedentes:
Dado un usuario con permisos para gestionar un agentes,
Y habiendo seleccionado el agente para el que tiene permisos,
Y estando en la gestion del presupuesto del agente

# añadir un preuspuesto
Escenario: 
  Cuando doy a "añadir presupuesto"
  Y relleno los datos de un presupuesto.
  Y doy a guardar.
  Entonces el listado de presupuesto se añade un nueva linea de presupuesto.

# borrar un preuspuesto
Escenario: 
  Y teniendo una linea de presupuesto,
  Cuando pulso en borrar presupuesto
  Y confirmo en la ventana de borrado
  Entonces se borra una linea del listado de presupuesto.


#modificar un preuspuesto
Escenario: 
  Y teniendo una linea de presupuesto
  Cuando pulso en modificar presupuesto
  Y relleno los datos del formulario
  Y pulso a guardar
  Entonces los datos de la linea del presupuesto aparecen modificados.



# language: es

# Ejemplo de feature de Cucumber:

# Característica: adición
# Para evitar hacer errores tontos
# Como un matemático idiota
# Quiero saber la suma de los números
# 
#   Esquema del escenario: Sumar dos números
#     Dado que he introducido <entrada_1> en la calculadora
#     Y que he introducido <entrada_2> en la calculadora
#     Cuando oprimo el <botón>
#     Entonces el resultado debe ser <resultado> en la pantalla
# 
#   Ejemplos:
#     | entrada_1 | entrada_2 | botón | resultado |
#     | 20 | 30 | add | 50 |
#     | 2 | 5 | add | 7 |
#     | 0 | 40 | add | 40 |

#   Escenario:

#   Escenario:

#   Escenario:

