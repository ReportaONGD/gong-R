# language: es

Característica: gestión de libros

  Escenario: Borro libro (Cuentas)
    Dado unos datos básicos
    Y hay un libro con el nombre "GONG_CONTRAPARTE" y con el agente "SOL" y con la moneda "Peso" y con el pais "Nicaragua" y la cuenta "88999 98980 82322" y el tipo "banco"
    Y el usuario admin autenticado y estando en Admin/Cuentas
    Cuando borro el 1º libro de la lista
    Entonces no queda ningún libro en la lista

  Escenario: Voy a sección
    Dado el usuario admin por defecto
    Y entro como usuario admin/admin
#    Entonces salva_y_abre_pagina
    Entonces pulso en la sección Admin
