class AddAdjuntoUrlToDocumento < ActiveRecord::Migration
  def change
    add_column :documento, :adjunto_url, :string
  end
end
