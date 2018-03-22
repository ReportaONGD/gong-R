class AddEntidadToLibro < ActiveRecord::Migration
  def change
    add_column :libro, :entidad, :string, default: ""
  end
end
