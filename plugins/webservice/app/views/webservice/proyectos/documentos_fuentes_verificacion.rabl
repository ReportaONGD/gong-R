object @proyecto => :documentos_fuentes_verificacion

child @fuentes_verificacion, :root => "fuentes" do |fuente|
  attributes :codigo, :descripcion

  child :documento => :documentos do
    attributes :id, :descripcion
    attributes :adjunto_file_name => :nombre
  end
end

