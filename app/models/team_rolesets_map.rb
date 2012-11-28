class TeamRolesetsMap < ActiveRecord::Base
  has_many :team_roles
  has_many :team_rolesets
end