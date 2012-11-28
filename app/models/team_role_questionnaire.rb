class TeamRoleQuestionnaire < ActiveRecord::Base
  has_many :team_roles
  has_many :questionnaires
end