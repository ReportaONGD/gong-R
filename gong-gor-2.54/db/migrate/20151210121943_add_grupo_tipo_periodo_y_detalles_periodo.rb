# encoding: UTF-8
#--
class AddGrupoTipoPeriodoYDetallesPeriodo < ActiveRecord::Migration
  def up
    # Añadimos caracterisitcas a los tipos de periodos
    add_column :tipo_periodo, :descripcion, :text
    add_column :tipo_periodo, :oficial, :boolean, default: false
    add_column :tipo_periodo, :no_borrable, :boolean, default: false
    add_column :tipo_periodo, :grupo_tipo_periodo, :string


    # Ampliamos la información de los periodos
    add_column :periodo, :fecha_informe, :date
    rename_column :periodo, :cerrado, :gastos_cerrados
    add_column :periodo, :periodo_cerrado, :boolean, default: false
    
    # Ampliamos la información de proyecto para poner fecha_limite_petición
    
    add_column :proyecto, :fecha_limite_peticion_prorroga, :date
    add_column :proyecto, :fecha_inicio_aviso_peticion_prorroga, :date
    
    # ESTO HAY QUE PASARLO AL SEEDS EN CUANTO ACABE!
    TipoPeriodo.reset_column_information
    puts "--------> Actualizamos los tipos de periodos"
    periodo = TipoPeriodo.find_or_create_by_nombre _("Informe Final")
    periodo.update_attributes :descripcion => _("Periodo completo de ejecución del proyecto al que corresponde el informe final") ,
                              :oficial => true, :no_borrable => true, :grupo_tipo_periodo => "final"
    #periodo.update_attribute "nombre", _("Informe Final (Periodo completo del proyecto)")
    periodo =TipoPeriodo.find_or_create_by_nombre _("Informe Intermedio")
    periodo.update_attributes :descripcion => _("Periodo intermedio al que corresponde un informe parcial requerido por el financiador"),
                              :oficial => true, :grupo_tipo_periodo => "seguimiento"
    #periodo.update_attribute "nombre", _("Informe Intermedio (Periodo parcial del proyecto)")
    periodo = TipoPeriodo.find_or_create_by_nombre _("Prorroga")
    periodo.update_attributes :descripcion => _("Prorroga requiere pedirse al financiador"),
                              :oficial => true, :no_borrable => true, :grupo_tipo_periodo => "prorroga"
    periodo = TipoPeriodo.find_or_create_by_nombre _("Seguimiento mensual")
    periodo.update_attributes :descripcion => _("Periodo de seguimiento mensual interno de la propia organización"),
                              :grupo_tipo_periodo => "seguimiento"
    periodo = TipoPeriodo.find_or_create_by_nombre _("Seguimiento trimestral")
    periodo.update_attributes :descripcion => _("Periodo de seguimiento trimestral interno de la propia organización"),
                              :grupo_tipo_periodo => "seguimiento"
    periodo = TipoPeriodo.find_or_create_by_nombre _("Seguimiento anual")
    periodo.update_attributes :descripcion => _("Periodo de seguimiento anual interno de la propia organización"),
                              :grupo_tipo_periodo => "seguimiento"
    periodo = TipoPeriodo.find_or_create_by_nombre _("Periodo de formulación")
    periodo.update_attributes :descripcion =>  _("Periodo de formulación. La fecha de presentación del informe se corresponde con la oficial marcada por el financiador"),
                              :oficial => true, :no_borrable => true, :grupo_tipo_periodo => "formulacion"
    Periodo.reset_column_information
    puts "--------> Actualizamos los información de periodos"
    Proyecto.all.each do |proyecto|
      estado = proyecto.estado_actual.definicion_estado if proyecto.estado_actual
      if estado and !estado.cerrado
        #Para cada periodo dentro de los proyectos abiertos ponemos una fecha de informe un mes despues de la fecha de fin
        proyecto.periodo.each do |periodo|
          if periodo.tipo_periodo != "prorroga"
            periodo.update_attribute :fecha_informe, periodo.fecha_fin >> 1
          end
        end
      end
    end
  end

  def down
    remove_column :tipo_periodo, :descripcion
    remove_column :tipo_periodo, :oficial
    remove_column :tipo_periodo, :no_borrable
    remove_column :tipo_periodo, :grupo_tipo_periodo
    remove_column :periodo, :fecha_informe
    rename_column :periodo, :gastos_cerrados, :cerrado
    remove_column :periodo, :periodo_cerrado
    remove_column :proyecto, :fecha_limite_peticion_prorroga
    remove_column :proyecto, :fecha_inicio_aviso_peticion_prorroga

    # periodo = TipoPeriodo.find_by_nombre _("Informe Final (Periodo completo del proyecto)")
    # periodo.update_attribute :nombre, _("Informe Final")
    # periodo = TipoPeriodo.find_by_nombre _("Informe Intermedio (Periodo parcial del proyecto)")
    # periodo.update_attribute :nombre, _("Informe Intermedio")
  end
end
