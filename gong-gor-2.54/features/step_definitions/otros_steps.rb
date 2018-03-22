# Adapted to Spanish from https://github.com/mdoel/cukesteps
# https://github.com/mdoel/cukesteps/blob/master/LICENSE
require 'rubygems'
require 'ruby-debug'

# Esto lo ponemos aqui hasta que averiguemos como pillarlo de capybara
module WithinHelpers
  def with_scope(locator)
    locator ? within(locator) { yield } : yield
  end
end
World(WithinHelpers)

Then /^debugeo$/ do
  debugger
end

Then /^salva_y_abre_pagina$/ do
  save_and_open_page
end

Then /^espero ([0-9]+) segundos$/ do |delay|
  sleep delay.to_i
end

Then /^deben? existir (\d+) (\S+) en la BD$/ do |count, element_class|
  klass = element_class.singularize.capitalize.constantize
  klass.count.should eql(count.to_i)
end

Then /^vuelca todo (\S+) a salida estandar$/ do |klass|
  klass_name = klass.singularize.capitalize.constantize
  records = klass_name.send(:find, :all)
  records.each { |record| puts record.inspect }
end

# Steps that are generally useful and help encourage use of semantic
# IDs and Class Names in your markup.  In the steps below, a match following
# "the" will verify the presences of an element with a given ID while a match following
# "a" or "an" will verify the presence an element of a given class.
Then /^(no )?debo ver el (\S+)$/ do |negation, element_id|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag("##{element_id}")
end

Then /^(no )?debo ver una? (\S+)$/ do |negation, element_class|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag(".#{element_class}")
end

Then /^(no )? debo ver una? (\S+) en el (\S+)$/ do |negation, element, containing_element|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag("##{containing_element} .#{element}")
end

Then /^(no )?debo ver el (\S+) en el (\S+)$/ do |negation, element, containing_element|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag("##{containing_element} ##{element}")
end

Then /^(no )?debo ver (\d+) (\S+) en el (\S+)$/ do |negation, count, element, containing_element|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag("##{containing_element} .#{element.singularize}",:count => count.to_i)
end

Then /^(no )?debo ver de (\d+) a (\d+) (\S+) en el (\S+)$/ do |negation, min, max, element, containing_element|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag("##{containing_element} .#{element.singularize}",min.to_i..max.to_i)
end

Then /^el (\S+) en (?:el|la) (\S+) (no )?debe contener una? (\S+)$/ do |middle_element, outer_element, negation, inner_element|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag("##{outer_element} ##{middle_element} .#{inner_element}")
end

# Test for page title. E.g.:
# Then the page title should be "Login"
Then /^el título de la página (no )? debe ser "(.*)"$/ do |negation, expectation|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag('title', CGI::escapeHTML(expectation))
end

# Test for presence in page title. E.g.:
# Then the page title should contain "Login" 
Then /^el título de la página (no )?debe contener "(.*)"$/ do |negation, expectation|
  matcher = negation.blank? ? :should : :should_not
  response.send matcher, have_tag('title', /#{CGI::escapeHTML(expectation)}/)
end

# Comprueba que este seleccionada una opcion en un selector
Then /^"([^"]*)" should be selected for "([^"]*)"(?: within "([^\"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    field_labeled(field).find(:xpath, ".//option[@selected = 'selected'][text() = '#{value}']").should be_present
  end
end

