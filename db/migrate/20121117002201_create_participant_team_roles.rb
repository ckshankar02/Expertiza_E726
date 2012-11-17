class CreateParticipantTeamRoles < ActiveRecord::Migration
  def self.up
    create_table :participant_team_roles do |t|
      t.integer :roleset_assignment_id
      t.integer :participant_id
      t.timestamps
    end
    execute "ALTER TABLE `participant_team_roles`
    ADD CONSTRAINT fk_roleset_assignment_id
    FOREIGN KEY (roleset_assignment_id) references team_roleset_assignments(id)"
    execute "ALTER TABLE `participant_team_roles`
    ADD CONSTRAINT fk_participant_id
    FOREIGN KEY (participant_id) references participants(id)"
  end

  def self.down
    execute "ALTER TABLE `participant_team_roles`
    DROP FOREIGN KEY fk_roleset_assignment_id"
    execute "ALTER TABLE `participant_team_roles`
    DROP FOREIGN KEY fk_participant_id"
    drop_table :participant_team_roles
  end
end
