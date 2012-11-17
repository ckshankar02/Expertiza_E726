class CreateTeamroleAssignment < ActiveRecord::Migration
  def self.up
    create_table "teamrole_assignment", :force => true do |t|
      t.integer "id"
      t.integer "team_roleset_id"
      t.integer "assignment_id"
    end
    execute "ALTER TABLE `teamrole_assignment`
             ADD CONSTRAINT `fk_teamrole_assignment_team_rolesets`
             FOREIGN KEY (team_roleset_id,assignment_id) references team_rolesets(id),assignments(id)"
  end

  def self.down
    execute ""
    drop_table :teamrole_assignment
  end
end
