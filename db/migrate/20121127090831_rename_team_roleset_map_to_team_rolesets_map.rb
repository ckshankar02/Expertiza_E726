class RenameTeamRolesetMapToTeamRolesetsMap < ActiveRecord::Migration
  def self.up
    rename_table :team_roleset_maps, :team_rolesets_maps
  end

  def self.down
    rename_table :team_rolesets_maps, :team_roleset_maps
  end
end
