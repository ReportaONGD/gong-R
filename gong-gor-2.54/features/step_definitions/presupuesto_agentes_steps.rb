Given /^the following presupuesto_agentes:$/ do |presupuesto_agentes|
  PresupuestoAgentes.create!(presupuesto_agentes.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) presupuesto_agentes$/ do |pos|
  visit presupuesto_agentes_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following presupuesto_agentes:$/ do |expected_presupuesto_agentes_table|
  expected_presupuesto_agentes_table.diff!(tableish('table tr', 'td,th'))
end
