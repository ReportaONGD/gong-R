# language: es

Característica: Acceso de usuarios
  Para acceder o no a Gong
  como administrador autenticado o no
  quiero comprobar el acceso y crear, editar y borrar usuarios

  Escenario: Acceder como admin
    Dado el usuario admin por defecto
    Cuando entro como usuario admin/admin
    Entonces debo acceder como usuario admin

  Escenario: No acceder con un usuario admin y contraseña incorrecta
    Dado el usuario admin por defecto
    Cuando entro como usuario admin/adminmal
    Entonces muestro mensaje de acceso denegado

  Escenario: No acceder con un usuario erroneo y contraseña correcta
    Dado el usuario admin por defecto
    Cuando entro como usuario admina/admin
    Entonces muestro mensaje de acceso denegado

  Escenario: Crear un usuario administrador
    Dado el usuario admin por defecto
    Cuando entro como usuario admin/admin
      Y me autentico correctamente como usuario admin
      Y pulso en la sección Admin
      Y pulso en el controlador Usuarios
      Y cree un usuario administrador nuevo
    Entonces el mensaje de notificación debe ser Los datos se han guardado correctamente.
    #Y el mensaje de notificación es verde

  Escenario: Editar un usuario
    Dado que existe un usuario nuevo
    Cuando edito el 2º usuario de la lista
      Y cambio el nombre de usuario a mengano
    Entonces el mensaje de notificación debe ser Los datos se han guardado correctamente.
      Y el mensaje de notificación es verde

  # Si queremos correr el test bajo selenium
  # @selenium
  Escenario: Borrar un usuario
    Dado que existe un usuario nuevo
    Cuando borro el 2º usuario de la lista
    Entonces desaparece el 2º usuario de la lista

