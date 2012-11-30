class RemoveQuestionnaireFieldFromTeamRoles < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `team_roles`
             DROP FOREIGN KEY `fk_team_roles_questionnaire`"
    remove_column :team_roles, :questionnaire_id
  end

  def self.down
    add_column :team_roles, :questionnaire_id, :integer
    execute "ALTER TABLE `team_roles`
             ADD CONSTRAINT `fk_team_roles_questionnaire`
             FOREIGN KEY (questionnaire_id) references questionnaires(id)"
  end
end
