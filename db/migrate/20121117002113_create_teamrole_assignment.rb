class CreateTeamroleAssignment < ActiveRecord::Migration
  def self.up
    create_table "teamrole_assignments", :force => true do |t|
      t.integer "id"
      t.integer "team_role_id"
      t.integer "assignment_id"
    end
    execute "ALTER TABLE `teamrole_assignments`
             ADD CONSTRAINT `fk_teamrole_assignments_team_roles`
             FOREIGN KEY (team_role_id) references team_roles(id)"
    execute "ALTER TABLE `teamrole_assignments`
             ADD CONSTRAINT `fk_teamrole_assignments_assignments`
             FOREIGN KEY (assignment_id) references assignments(id)"

  end

  def self.down
    drop_table :teamrole_assignments
  end
end
