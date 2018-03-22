class CreateTimestampsOnProyectos < ActiveRecord::Migration
  def change
    add_timestamps :proyecto
  end
end
