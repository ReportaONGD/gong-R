# This is an example of how you can set up screenshots for your
# browser testing. Just run cucumber with --format html --out report.html
#
module Screenshots
  def embed_screenshot(id)
    # NOTA: apt-get install scrot
    %x(scrot tmp/capybara/#{id}.png)
  end
end
World(Screenshots)

# Only take screenshot for scenarios or features tagged @screenshot

#After(@screenshots) do
#  timestamped
#end

#After(@captura) do
#  timestamped
#end

# Only take screenshot on failures

After do |scenario|
  embed_screenshot(scrname("#{scenario.name}")) if scenario.failed?
end

Then "screenshot" do
  timestamped
end

Then "haz una captura" do
  timestamped
end

def timestamped
  embed_screenshot("screenshot-#{Time.new.to_i}")
  #embed_screenshot("screenshot-#{scenario.id}")
end

def scrname base
  #return "screenshot-" + base.gsub(" ", "_").camelize
  return "screenshot-#{Time.new.to_i}"
end

# Other variants:
#
# After do
# $stderr.puts "Attempting to make a screenshot" if $DEBUG
# embed_screenshot("screenshot-#{scenario.name}-#{Time.new.to_i}")
# $stderr.puts "Ok !" if $DEBUG
# end
