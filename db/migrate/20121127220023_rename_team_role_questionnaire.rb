class RenameTeamRoleQuestionnaire < ActiveRecord::Migration
  def self.up
    rename_table :team_role_questionnaire, :team_role_questionnaires
  end

  def self.down
    rename_table :team_role_questionnaires, :team_role_questionnaire
  end
end
