# language: es

Característica: gestión de proyectos
	#  Esquema del escenario: creo el PROYECTO-1
	#Dado el usuario admin
  Esquema del escenario: Creo, edito y borro proyectos
    Dado el usuario admin
    Y unos datos básicos
    Cuando me autentico y voy a la sección Admin y controlador Proyectos
      # Añado
      Y hago click en "Añadir proyecto"
      Y relleno lo siguiente:
        | proyecto_nombre    | <nombre> |
        | proyecto_titulo    | <titulo> |
	| proyecto_moneda_id | <moneda> |
	| proyecto_agente_id | <agente> |
      Y pulso "Guardar"
      # Edito
      Y edito el 1º proyecto de la lista
      Y relleno lo siguiente:
        | proyecto_nombre    | <nombre>2 |
        | proyecto_titulo    | <titulo>2 |
	| proyecto_moneda_id | Euro      |
        | proyecto_agente_id | AECI      |
      Y pulso "Guardar"
    Entonces se tiene que mostrar 1 proyectos en el listado
    Y en el 1º proyecto debe tener lo siguiente:
        | proyecto_nombre    | <nombre>2 |
        | proyecto_titulo    | <titulo>2 |
	| proyecto_moneda_id | Euro      |
        | proyecto_agente_id | AECI      |

  Ejemplos:
    | nombre               | titulo                                                                     | estado        | moneda | agente |
    | 02-MOZ-MAPUTO        | Proyecto 1: Mejora de la gestión del sector agroindustrial en Mozambique   | aprobado      | Euro   | AECI   |
    | 09-IMPLANTACION-GONG | Proyecto para la implantacion de GONG en las ONGs primera segunda y ter... | aprobado      | Euro   | AECI   |
    | 09-MOZ-UGC           | Proyecto desarrollo rural mozambique                                       | identifica... | Euro   | AECI   |
    | PROYECTO 2           | Proyecto 2                                                                 | aprobado      | Euro   | AECI   |

  Escenario: Borro proyectos
    Dado unos datos básicos
    Y que existe un proyecto por defecto
    Y el usuario admin autenticado y estando en Admin/Proyectos
    Cuando estoy en Admin > Proyectos
    Y borro el 1º proyecto de la lista
    Entonces no queda ningún proyecto en la lista

  Escenario: Repito proyecto.
      Dado unos datos básicos
      Y que existe un proyecto por defecto
      Y el usuario admin autenticado y estando en Admin/Proyectos
      Cuando hago click en "Añadir proyecto"
      Y relleno lo siguiente:
        | proyecto_nombre    | 01-MOZ-MAPUTO |
        | proyecto_titulo    | Proyecto de prueba |
	      | proyecto_moneda_id | Euro |
      	| proyecto_agente_id | AECI |
      Y pulso "Guardar"
      Entonces el mensaje de notificación es rojo 
      Y el mensaje de notificación debe ser Nombre repetido.


@javascript
  Escenario: vincular un usuario.
      Dado unos datos básicos
      Y que existe un proyecto por defecto
      Y el usuario admin autenticado y estando en Admin/Proyectos
      Cuando abro el sublistado de usuarios del 1º proyecto de la lista
      Y pulso en añadir usuario al sublistado del 1º proyecto de la lista
      Y relleno lo siguiente:
      | usuario_usuario_id | admin |
      | usuario_rol | Coordinador |
      Y pulso "Guardar" formulario
      Entonces el sublistado del 1º proyecto debe mostrar 1 fila de usuarios
      Y la 1º fila del sublistado de usuarios del 1º proyecto debe tener lo siguiente:
      | valor_usuario.nombre | admin |
      | valor_rol | coordinador |


  Escenario: fuegote
      Dado unos datos básicos
      Y que existe un proyecto por defecto
      Y el usuario admin autenticado y estando en Admin/Proyectos
      Cuando hago click en "Añadir proyecto"
      Y busco el rotulo Título
      


