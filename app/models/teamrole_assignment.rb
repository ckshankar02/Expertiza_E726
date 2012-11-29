class TeamroleAssignment < ActiveRecord::Base
      has_many :team_roles
      has_many :assignments
end