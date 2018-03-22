Dado /^que existe un proyecto por defecto$/ do
  # Nota: Ojo usar el español aquí parece que no funciona
  steps %Q{
    Given "PROYECTO-01" es un proyecto con el nombre "01-MOZ-MAPUTO" y el titulo "Proyecto 0: Mejora de no se que" y la moneda_id "Euro" y el agente_id "AECI"
  }
end

Dado /^que existen dos proyectos por defecto$/ do
  steps %Q{
    Given "PROYECTO-01" es un proyecto con el nombre "PROYECTO-01" y el titulo "Proyecto 0: Mejora de no se que" y la moneda_id "Euro" y el agente_id "AECI"
    Given "PROYECTO-02" es un proyecto con el nombre "PROYECTO-02" y el titulo "Proyecto 1: Mejora de otra cosa" y la moneda_id "Euro" y el agente_id "AECI"
  }
end
