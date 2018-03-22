# encoding: UTF-8
#--
#
#################################################################################
# Copyright 2010-2013 Free Software's Seed, CENATIC y IEPALA
#
# Licencia con arreglo a la EUPL, Versión 1.1 o –en cuanto sean aprobadas por la Comisión Europea– 
# versiones posteriores de la EUPL (la «Licencia»);
# Solo podrá usarse esta obra si se respeta la Licencia.
# Puede obtenerse una copia de la Licencia en:
#
# http://www.osor.eu/eupl/european-union-public-licence-eupl-v.1.1
#
# Salvo cuando lo exija la legislación aplicable o se acuerde por escrito, 
# el programa distribuido con arreglo a la Licencia se distribuye «TAL CUAL»,
# SIN GARANTÍAS NI CONDICIONES DE NINGÚN TIPO, ni expresas ni implícitas.
# Véase la Licencia en el idioma concreto que rige los permisos y limitaciones que establece la Licencia.
#################################################################################
#
#++
# ActiveResource que devuelve usuarios vinculados a grupos

class UsuarioXGrupoUsuario < ActiveRecord::Base

  belongs_to :grupo_usuario
  belongs_to :usuario
  validates_presence_of :grupo_usuario_id, :message => _("Grupo") + " " + _("no puede estar vacío.")
  validates_presence_of :usuario_id, :message => _("Usuario") + " " + _("no puede estar vacío.")
  validates_uniqueness_of :usuario_id, :scope => :grupo_usuario_id, :message => _("Usuario repetido.")

  after_save :crea_usuarios
  after_destroy :limpia_usuarios

  # Metodo falso para simplificar las cosas en el controlador
  def rol=(cadena)
  end

 private

  def crea_usuarios
    GrupoUsuarioXProyecto.where(:grupo_usuario_id => self.grupo_usuario_id).each do |objeto|
      uxo = UsuarioXProyecto.find_by_usuario_id_and_proyecto_id_and_grupo_usuario_id(self.usuario_id, objeto.proyecto_id, self.grupo_usuario_id) ||
            UsuarioXProyecto.new(usuario_id: self.usuario_id, proyecto_id: objeto.proyecto_id, grupo_usuario_id:  self.grupo_usuario_id)
      uxo.update_attribute(:rol_id, objeto.rol_id) if uxo
    end
    GrupoUsuarioXAgente.where(:grupo_usuario_id => self.grupo_usuario_id).each do |objeto|
      uxa = UsuarioXAgente.find_by_usuario_id_and_agente_id_and_grupo_usuario_id(self.usuario_id, objeto.agente_id, self.grupo_usuario_id) ||
            UsuarioXAgente.new(usuario_id: self.usuario_id, agente_id: objeto.agente_id, grupo_usuario_id:  self.grupo_usuario_id)
      uxa.update_attribute(:rol_id, objeto.rol_id) if uxa
    end
    GrupoUsuarioXLibro.where(:grupo_usuario_id => self.grupo_usuario_id).each do |objeto|
      UsuarioXLibro.find_or_create_by_usuario_id_and_libro_id_and_grupo_usuario_id(self.usuario_id, objeto.libro_id, self.grupo_usuario_id)
    end
    GrupoUsuarioXEspacio.where(:grupo_usuario_id => self.grupo_usuario_id).each do |objeto|
      UsuarioXEspacio.find_or_create_by_usuario_id_and_espacio_id_and_grupo_usuario_id(self.usuario_id, objeto.espacio_id, self.grupo_usuario_id)
    end
  end

  def limpia_usuarios
    UsuarioXProyecto.where(grupo_usuario_id: self.grupo_usuario_id, usuario_id: self.usuario_id).destroy_all
    UsuarioXAgente.where(grupo_usuario_id: self.grupo_usuario_id, usuario_id: self.usuario_id).destroy_all
    UsuarioXLibro.where(grupo_usuario_id: self.grupo_usuario_id, usuario_id: self.usuario_id).destroy_all
    UsuarioXEspacio.where(grupo_usuario_id: self.grupo_usuario_id, usuario_id: self.usuario_id).destroy_all
  end
end

