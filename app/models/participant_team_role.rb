class ParticipantTeamRole < ActiveRecord::Base
  has_many :participants
  has_many :teamrole_assignments
end