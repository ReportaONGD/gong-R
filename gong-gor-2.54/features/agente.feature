# language: es

Característica: gestión de agentes


  Esquema del escenario: Creo, edito y borro agentes
    Dado el usuario admin
    Cuando me autentico y voy a la sección Admin y controlador Agentes
      # Añado
      Y hago click en "Nuevo agente"
      Y relleno lo siguiente:
        | agente_nombre          | <nombre>          |
        | agente_nombre_completo | <nombre_completo> |
        | agente_financiador     | <financiador>     |
        | agente_implementador   | <implementador>   |
      Y pulso "Guardar"
      # Edito
      Y edito el 1º agente de la lista
      Y relleno lo siguiente:
        | agente_nombre          | <nombre>2          |
        | agente_nombre_completo | <nombre_completo>2 |
        | agente_financiador     | No                 |
        | agente_implementador   | No                 |
      Y pulso "Guardar"
    Entonces se tiene que mostrar 1 agentes en el listado
    Y en el 1º agente debe tener lo siguiente:
        | agente_nombre          | <nombre>2          |
        | agente_nombre_completo | <nombre_completo>2 |
        | agente_financiador     | No                 |
        | agente_implementador   | No                 |

  Ejemplos:
    | nombre  | nombre_completo                                                                                   | financiador | implementador |
    | AECI    | Agencia Española de Cooperación                                                                   | Sí          | No            |
    | ONG-INT | ONG internacional para el desarrollo                                                              | Sí          | No            |
    | SOL     | Aquí se podría probar nombres raros, largos incluso chino 吗 台湾 六种辅音韵尾 中国政府要求在中国 | Sí          | No            |

  Escenario: Borro agentes
    Dado un agente con el nombre "AECI" y el nombre completo "Agencia Estatal" y que no es financiador y que no es implementador
    Y el usuario admin autenticado y estando en Admin/Agentes
    Entonces se tiene que mostrar 1 agentes en el listado
    #Comento esto pq no se cerrar el modal de editar
    #Y en el 1º agente debe tener lo siguiente:
    #    | agente_nombre          | AECI                                 |
    #    | agente_nombre_completo | Agencia Estatal                      |
    #    | agente_financiador     | No                                   |
    #    | agente_implementador   | No                                   |
    Y borro el 1º agente de la lista
    Entonces no queda ningún agente en la lista

