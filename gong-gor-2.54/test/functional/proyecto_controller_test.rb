require 'test_helper'class ProyectoControllerTest < ActionController::TestCase
  test "index should redirect to ordenado" do
    session[:usuario_identificado] = Usuario.find_by_nombre("admin")
    session[:por_pagina] = 20
    get  "index", :seccion => "administracion", :controller => "proyecto"
    assert_redirected_to "/administracion/proyecto/ordenado" 
  end 

  test "proyecto nuevo usuario debe ser admin" do
    assert_no_difference('Proyecto.count') do 
      proyecto :create, :proyecto => { :nombre => "proyecto 1", :titulo => "un proyecto para test de autorización", :pais_id => 1 }
    end
    assert_redirected_to "/administracion/proyecto/listado"
  end
end
