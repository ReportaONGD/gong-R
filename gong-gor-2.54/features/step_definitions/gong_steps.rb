# Aquí va todo lo general de GONG

#require "app/helpers/application_helper
include ApplicationHelper


# Notificaciones

Entonces /^el mensaje de notificación debe ser (.*)$/ do |mensaje|
  page.should have_content(mensaje)
end

Entonces /^el mensaje de notificación es verde$/ do
  page.should have_selector("#mensajeok")
end

Entonces /^el mensaje de notificación es rojo$/ do
  page.should have_selector("#mensajeerror")
end

Entonces /^muestro mensaje de acceso denegado$/ do
  page.should have_no_content("[ admin ]")
  page.should have_content("Entrada")
end

# Navegación

Cuando /^pulso en la sección (.*)$/ do |seccion|
  click_link "seccion_" + seccion.downcase.gsub(/admin/,"administracion")
end

Cuando /^pulso en el controlador (.*)$/ do |controlador|
  click_link controlador
end

Cuando /^entro y voy a (.*) > (.*) > (.*)$/ do |seccion, controlador, subcontrolador|
  Dado "el usuario admin por defecto"
  Cuando "entro como usuario admin/admin"
  Cuando "pulso en la sección #{seccion}"
  Cuando "pulso en el controlador #{controlador}"
  click_link subcontrolador
end

Cuando /^(?:|yo )pulso "([^"]*)"(?: within "([^"]*)")?$/ do |button, selector|
  with_scope(selector) do
    click_button(button)
  end
end

# Chapuzas en pruebas
Cuando /^(?:|yo )pulso "([^"]*)" formulario$/ do |button|
  with_scope("#formulario") do
    click_button(button)
  end
end

Cuando /^(?:|yo )hago click en "([^"]*)"(?: within "([^"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

Cuando /^voy a (.*) > (.*) > (.*)$/ do |seccion, controlador, subcontrolador|
  Cuando "pulso en la sección #{seccion}"
  Cuando "pulso en el controlador #{controlador}"
  click_link subcontrolador
end

Cuando /^estoy en (.*) > (.*)$/ do |seccion, controlador|
  Cuando "voy a #{seccion} > #{controlador}"
end

Cuando /^voy a (.*) > (.*)$/ do |seccion, controlador|
  Cuando "pulso en la sección #{seccion}"
  Cuando "pulso en el controlador #{controlador}"
end

# Formularios

Cuando /^(?:|yo )relleno lo siguiente(?: within "([^"]*)")?:$/ do |selector, fields|
  with_scope(selector) do
    fields.rows_hash.each do |name, value|
      if page.has_select?(name)
        select(value, :from => name)
      else
        if page.has_checked_field?(name)
          # Esto está un poco sin probar 100%
          if (value == "Sí")
            check(name)
          else
            uncheck(name)
          end
        else
          When %{I fill in "#{name}" with "#{value}"}
        end
      end
    end
  end
end

# Esto habria que modificarlo ¿No?. Ahora los campos de los listados llevan las etiquedas adecuadas ¿No?
# Y si no lo hacemos nosotros.

Entonces /^en (?:el|la) (\d+)(?:º|ª) (.*) debe tener lo siguiente(?: within "([^"]*)")?:$/ do |fila, controlador, selector, fields|
  find("#" + singular(controlador) + "_" + fila + "_editar").click
  fields.rows_hash.each do |name, value|
    if page.has_select?(name)
      # Esto está un poco sin probar 100%
      if (value == "No")
        Then %{the "#{name}" field should contain "false"}
      else
        if (value == "Sí") then
          Then %{the "#{name}" field should contain "true"}
        else
          #Then %{the "#{name}" field should contain "#{value}"}
          Then %{"#{value}" should be selected for "#{name}"}
        end
      end
    else
      if page.has_checked_field?(name)
        if (value == "Sí")
          Then %{checkbox("#{name}") should be checked}
        else
          Then %{checkbox("#{name}") should be unchecked}
        end
      else
        Then %{the "#{name}" field should contain "#{value}"}
      end
    end
  end
  # FIXME esto no consigo que funcione (cerrar el modal). Usar save_and... para ver con claridad lo que sucede
  #save_and_open_page
  #click_link "#MB_close"
end

# Listados

Entonces /^se tiene que mostrar (\d+) (.*) en el listado$/ do |fila, controlador|
  page.should have_selector("#" + singular(controlador) + "_" + fila)
  page.should have_no_selector("#" + singular(controlador) + "_" + (fila.to_i + 1).to_s)
end

# Sublistados.

Cuando /^abro (?:el|la) sublistado de (.*) del (\d+)(?:º|ª) (.*) de la lista$/ do |sublistado, fila, controlador|
  find("#" + singular(controlador) + "_" + fila + "_" + sublistado ).click
  save_and_open_page
end

Cuando /^pulso en añadir (.*) al sublistado del (\d+)(?:º|ª) (.*) de la lista$/ do |sublistado, fila, controlador|
  find("#" + singular(controlador) + "_sub_" + fila + "_" + sublistado + "_anadir" ).click
  save_and_open_page
end

Entonces /^el sublistado del (\d+)(?:º|ª) (.*) debe mostrar (\d+) (?:fila|filas) de (.*)$/ do |fila, controlador, subfilas, sublistado|
  save_and_open_page
  page.has_selector?("#" + singular(controlador) + "_sub_" + fila + "_" + sublistado + "_" + subfilas)
  page.has_no_selector?("#" + singular(controlador) + "_sub_" + fila + "_" + sublistado + "_" + (subfilas.to_i + 1).to_s)
end

        
Entonces /^ la (\d+)(?:º|ª) fila del sublistado de (.*) del (\d+)(?:º|ª) (.*) debe tener lo siguiente:$/ do |subfilas, sublistado, fila, controlador, fields|
    fields.rows_hash.each do |name, value|
      page.has_selector("#" + singular(controlador) + "_sub_" + fila + "_" + sublistado + "_" + subfilas + "_" + name  )
    end
end

# Chapuza de prueba. Este no deberia existir pero el anterior no me funciona.
Entonces /^la (\d+)º fila del sublistado de usuarios del (\d+)º proyecto debe tener lo siguiente:$/ do |a, b, fields|
    save_and_open_page
    fields.rows_hash.each do |name, valor|
      page.has_selector?("#" +"proyecto_sub_" + b + "_usuarios_" + a + "_" + name  ).value == valor
    end
end
  


# Edición y borrado

Cuando /^borro (?:el|la) (\d+)(?:º|ª) (.*) de la lista$/ do |fila, controlador|
  within ("#" + singular(controlador) + "_" + fila) do
    click_link "eliminar"
  end
  within ("#" + controlador + "_" + fila + "_borrar_modalconfirmar") do
    click_link "Confirmar"
  end
end

Cuando /^edito (?:el|la) (\d+)(?:º|ª) (.*) de la lista$/ do |fila, controlador|
  find("#" + singular(controlador) + "_" + fila + "_editar").click
end

Entonces /^desaparece (?:el|la) (\d+)(?:º|ª) (.*) de la lista$/ do |fila, controlador|
  page.should have_no_selector("#" + singular(controlador) + "_" + fila)
end

Entonces /^no queda (?:ningún|ninguna) (.*) en la lista$/ do |controlador|
  page.should have_no_selector("#" + singular(controlador) + "_1")
end

# Varios

Entonces /^el singular de (.*) es (.*)$/ do |nombre, singular|
  assert singular == singular(nombre)
end

def singular nombre
#  Entonces "debugeo"
  nombre.singularize.gsub(/one$/, "on").gsub(/paise/, "pais").gsub(" ", "").downcase.parameterize
end

