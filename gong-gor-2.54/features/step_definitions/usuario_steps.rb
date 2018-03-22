# Acceso de usuarios

Dado /^el usuario admin por defecto$/ do
    Usuario.create!([{ :nombre => 'admin', :contrasena => Digest::SHA1.hexdigest('admin'), :correoe => 'gong@ejemplo.org', :administracion => true }])
end

Cuando /^entro como usuario (.*)\/(.*)/ do |usuario,password|
  visit "/administracion/usuario/entrada"
  fill_in "usuario_nombre", :with => usuario
  fill_in "usuario_contrasena", :with => password
  click_button "Enviar"
end

Cuando /^me autentico correctamente como usuario (.*)$/ do |usuario|
  Entonces "debo acceder como usuario #{usuario}"
end

Entonces /^debo acceder como usuario (.*)$/ do |usuario|
  within ("#usuario") do
    page.should have_content(usuario)
  end
end

Dado /^el usuario admin autenticado y estando en (.*)\/(.*)$/ do |seccion, controlador|
  Dado "el usuario admin por defecto"
  Cuando "entro como usuario admin/admin"
  Cuando "pulso en la sección #{seccion}"
  Cuando "pulso en el controlador #{controlador}"
end

Cuando /^me autentico y voy a la sección (.*) y controlador (.*)$/ do |seccion,controlador|
  Cuando "entro como usuario admin/admin"
  Cuando "pulso en la sección #{seccion}"
  Cuando "pulso en el controlador #{controlador}"
end

# Creación de usuarios

Cuando /^cree un usuario administrador nuevo$/ do
  click_link "Nuevo usuario"
  fill_in "usuario_nombre", :with => "Fulano"
  fill_in "usuario_nombre_completo", :with => "Fulano mengano"
  fill_in "usuario_contrasena", :with => "secret"
  fill_in "usuario_correoe", :with => "fulano@example.com"
  click_button "Guardar"
end

# Edición de usuarios

Cuando /^cambio el nombre de usuario a (.*)$/ do |nombre|
  fill_in "usuario_nombre", :with => "Mengano"
  click_button "Guardar"
end

# Borrado de usuarios
Dado /^el usuario admin$/ do
  Dado "el usuario admin por defecto"
end

Dado /^que existe un usuario nuevo$/ do
  Dado "el usuario admin por defecto"
  Cuando "entro como usuario admin/admin"
  Cuando "pulso en la sección Admin"
  Cuando "pulso en el controlador Usuarios"
  Cuando "cree un usuario administrador nuevo"
end

