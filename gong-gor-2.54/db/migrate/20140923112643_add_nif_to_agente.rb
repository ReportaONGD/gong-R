class AddNifToAgente < ActiveRecord::Migration
  def change
    add_column :agente, :nif, :string, :default => ""
  end
end
