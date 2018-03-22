# language: es

Característica: Comprabación de datos básicos

Escenario: compruebo que los datos básicos incluye los paises
  Dado unos datos básicos
  Cuando entro y voy a Admin > Datos Básicos > Pais
  Entonces se tiene que mostrar 3 paises en el listado

Escenario: compruebo que los datos básicos incluye las areas geográficas
  Dado unos datos básicos
  Cuando entro y voy a Admin > Datos Básicos > A. Geográfica
  Entonces se tiene que mostrar 3 area geográficas en el listado

Escenario: compruebo que los datos básicos incluye las monedas
  Dado unos datos básicos
  Cuando entro y voy a Admin > Datos Básicos > Moneda
  Entonces se tiene que mostrar 3 monedas en el listado
  Y deben existir 3 monedas en la BD

Escenario: compruebo que los datos básicos incluye las partidas
  Dado unos datos básicos
  Cuando entro y voy a Admin > Datos Básicos > Partida
  Entonces se tiene que mostrar 5 partidas en el listado

Escenario: compruebo que los datos básicos incluye los sectores de población
  Dado unos datos básicos
  Cuando entro y voy a Admin > Datos Básicos > Sec. Población
  Entonces se tiene que mostrar 3 sector poblaciones en el listado

Escenario: compruebo que los datos básicos incluye los sectores de intervención
  Dado unos datos básicos
  Cuando entro y voy a Admin > Datos Básicos > Sec. Intervención
  Entonces se tiene que mostrar 3 sector intervencion en el listado

Escenario: compruebo que los datos básicos incluye las areas de actuación
  Dado unos datos básicos
  Cuando entro y voy a Admin > Datos Básicos > A. Actuación
  Entonces se tiene que mostrar 3 area actuacion en el listado
  #Y screenshot
  Y haz una captura
