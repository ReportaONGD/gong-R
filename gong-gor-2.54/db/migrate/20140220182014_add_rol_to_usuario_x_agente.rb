class AddRolToUsuarioXAgente < ActiveRecord::Migration
  def up
    add_column :usuario_x_agente, :rol, :string, :default => 'usuario'
    add_column :grupo_usuario_x_agente, :rol, :string, :default => 'usuario'
    # Para aquellos usuarios que tenian acceso a la seccion de agentes, les da el rol economico
    UsuarioXAgente.reset_column_information
    UsuarioXAgente.where(:grupo_usuario_id => nil).each do |uxa|
      uxa.update_column(:rol, "economico") if uxa.usuario.agentes
    end
  end

  def down
    remove_column :grupo_usuario_x_agente, :rol
    remove_column :usuario_x_agente, :rol
  end
end
