# encoding: UTF-8
class AddProrrogaJustificacionToTipoPeriodo < ActiveRecord::Migration
  def change
    # Creamos el nuevo periodo de prorroga
    periodo = TipoPeriodo.find_or_create_by_nombre _("Prorroga Justificación Final")
    periodo.update_attributes descripcion: _("Prorroga a la justificación final de un proyecto. Requiere de aprobación del Financiador."),
                              oficial: true, no_borrable: true, grupo_tipo_periodo: "prorroga_justificacion"
    # Creamos los campos de fechas de prorroga de justificacion
    add_column :proyecto, :fecha_limite_peticion_prorroga_justificacion, :date
    add_column :proyecto, :fecha_inicio_aviso_peticion_prorroga_justificacion, :date
  end
end
