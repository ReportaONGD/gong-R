# Cambio de contraseña para la instancias de demo
# Para no crear nuevos usuarios (con todos los permisos asociados) modificamos el usuario basico admin.

if ENV['DEMO']
  # Correo de información de los diferentes registros
  DEMO_CORREO_INFO ="info@gong.es"
  if ENV['DEMO_PASS']
    # Si existe la variable de entorno DEMO_PASS la elegimos
    DEMO_PASS = ENV['DEMO_PASS']
  else
    # Contrasena aleatoria si no hay DEMO_PASS
    DEMO_PASS =  (0...10).map { ('a'..'z').to_a[rand(26)] }.join
  end
  # Rails.logger.info (">>>>>>>>>>>>>> Modo demo. DEMO_PASS: " + DEMO_PASS)
  # Si se quiere mantener una contraseña fija para la demo sin variable de entorno descomentar:
  # DEMO_PASS = "contrasena123"
  admin = Usuario.find_by_nombre('admin')
  admin.contrasena = Usuario.hash_contrasena DEMO_PASS  
  admin.save
end

