class StudentTeamController < ApplicationController
  auto_complete_for :user, :name
   
  def view
    @all_team_roles = Array.new
    @team_member = Array.new
    @team_member_role = Array.new
    @role_selected_flag = 0

    @student = AssignmentParticipant.find(params[:id])
    return unless current_user_id?(@student.user_id)
    
    @send_invs = Invitation.find(:all, :conditions => ['from_id = ? and assignment_id = ?', @student.user.id, @student.assignment.id])
    @received_invs = Invitation.find(:all, :conditions => ['to_id = ? and assignment_id = ? and reply_status = "W"', @student.user.id, @student.assignment.id])

    @roles_for_assignment = TeamroleAssignment.find_all_by_assignment_id(@student.assignment.id)
    @roles_for_assignment.each do |x|
      @all_team_roles << TeamRole.find(x.team_role_id)
    end
#****************************** E726 Changes starts here *********************************************
#The team of the currently logged in user is determined

    assignment_teams = Team.find_all_by_parent_id(@student.parent_id)

    current_team_id = 0
    assignment_teams.each do |x|
      find_user_team = TeamsUser.find_all_by_team_id(x.id)
      find_user_team.each do |x1|
        if(x1.user_id == session[:user].id)           #Team of the current session user
          current_team_id = x1.team_id
        end
      end
    end
    team_mem_id = 0
    #All the members of the selected team are populated
    team_mem_id = TeamsUser.all(:conditions => ["team_id = ?",current_team_id])

    team_mem_id.each do |x|
      team_user_info = User.find(x.user_id)
      @team_member << team_user_info
    end


    @team_member.each do |x|
        getParticipant = Participant.all(:conditions => ["user_id = ? and parent_id = ?",x.id,@student.assignment.id]).first
        getRoleAssignmentId = ParticipantTeamRole.find_by_participant_id(getParticipant.id)
        if(getRoleAssignmentId.nil?)
          @team_member_role << NIL
          if x.id == session[:user].id
            @role_selected_flag = 1
          end
        else
          getRole = TeamroleAssignment.find(getRoleAssignmentId.role_assignment_id)
          @team_member_role << TeamRole.find(getRole.team_role_id)
        end
    end

#*********************************** E726 Changes Ends Here *****************************************

  end

  def select_role
    @part_team_role  = ParticipantTeamRole.new
    role_taken = params[:team_member_roles].to_i
    assignment_identifier = params[:current_assignment_id].to_i
    get_teamrole_assignment = TeamroleAssignment.find(:all, :conditions => ["team_role_id = ? and assignment_id = ?",role_taken, assignment_identifier]).first
    @part_team_role.role_assignment_id = get_teamrole_assignment.id
    @part_team_role.participant_id = params[:part_id]
    @part_team_role.save

    redirect_to :controller => 'student_team', :action => 'view' , :id => params[:part_id]
  end


  def create
    @student = AssignmentParticipant.find(params[:id])
    return unless current_user_id?(@student.user_id)

    check = AssignmentTeam.find(:all, :conditions => ["name =? and parent_id =?", params[:team][:name], @student.parent_id])        
    @team = AssignmentTeam.new(params[:team])
    @team.parent_id = @student.parent_id    
    #check if the team name is in use
    if (check.length == 0)      
      @team.save
      parent = AssignmentNode.find_by_node_object_id(@student.parent_id)
      TeamNode.create(:parent_id => parent.id, :node_object_id => @team.id)
      user = User.find(@student.user_id)
      @team.add_member(user)      
      redirect_to :controller => 'student_team', :action => 'view' , :id=> @student.id
    else
      flash[:notice] = 'Team name is already in use.'
      redirect_to :controller => 'student_team', :action => 'view' , :id=> @student.id
    end 
  end
  
  def edit 
    @team = AssignmentTeam.find_by_id(params[:team_id])
    @student = AssignmentParticipant.find(params[:student_id])
    return unless current_user_id?(@student.user_id)
  end
  
  def update
    @team = AssignmentTeam.find_by_id(params[:team_id])
    check = AssignmentTeam.find(:all, :conditions => ["name =? and parent_id =?", params[:team][:name], @team.parent_id])    
    if (check.length == 0)
       if @team.update_attributes(params[:team])
          redirect_to :controller => 'student_team', :action => 'view', :id => params[:student_id]
       end
    elsif (check.length == 1 && (check[0].name <=> @team.name) == 0)
      redirect_to :controller => 'student_team', :action => 'view', :id => params[:student_id]
    else
      flash[:notice] = 'Team name is already in use.'
      redirect_to :controller =>'student_team', :action => 'edit', :team_id =>params[:team_id], :student_id => params[:student_id]
    end 
  end

  def advertise_for_partners
      puts "team #{params[:team_id]}"
      Team.update_all("advertise_for_partner=true",:id=>params[:team_id])
      #respond_to do |format|
      #  format.html #  index.html.erb
      #format.xml  { render :xml => @log_entries }
      #end
      #redirect_to :controller => 'student_team', :action => 'advertise_for_partners' , :id => params[:team_id]
  end
  def remove
    Team.update_all("advertise_for_partner=false",:id=>params[:team_id])
    redirect_to :controller => 'student_team', :action => 'view' , :id => params[:team_id]
  end

  def leave
    @student = AssignmentParticipant.find(params[:student_id])
    return unless current_user_id?(@student.user_id)
    
    #remove the entry from teams_users
    user = TeamsUser.find(:first, :conditions =>["team_id =? and user_id =?", params[:team_id], @student.user_id])
    if user
      user.destroy
    end
    
    #if your old team does not have any members, delete the entry for the team
    other_members = TeamsUser.find(:all, :conditions => ['team_id = ?', params[:team_id]])
    if other_members.length == 0
      old_team = AssignmentTeam.find(:first, :conditions => ['id = ?', params[:team_id]])
      if old_team != nil
        old_team.destroy
        #if assignment has signup sheet then the topic selected by the team has to go back to the pool
        #or to the first team in the waitlist
        signups = SignedUpUser.find(:all, :conditions => {:creator_id => params[:team_id]})
        signups.each {|signup|
          #get the topic_id
          signup_topic_id = signup.topic_id
          #destroy the signup
          signup.destroy
          
          #get the number of non-waitlisted users signed up for this topic
          non_waitlisted_users = SignedUpUser.find(:all, :conditions => {:topic_id => signup_topic_id, :is_waitlisted => false})
          #get the number of max-choosers for the topic
          max_choosers = SignUpTopic.find(:first, :conditions => {:id => signup_topic_id}).max_choosers
          
          #check if this number is less than the max choosers
          if non_waitlisted_users.length < max_choosers
            first_waitlisted_user = SignedUpUser.find(:first, :conditions => {:topic_id => signup_topic_id, :is_waitlisted => true})
  
            #moving the waitlisted user into the confirmed signed up users list
            if !first_waitlisted_user.nil?
              first_waitlisted_user.is_waitlisted = false
              first_waitlisted_user.save

              waitlisted_team_user = TeamsUser.find(:first, :conditions => {:team_id => first_waitlisted_user.creator_id})
              #waitlisted_team_user could be nil since the team the student left could have been the one waitlisted on the topic
              #and teams_users for the team has been deleted in one of the earlier lines of code
              
             if !waitlisted_team_user.nil?
                user_id = waitlisted_team_user.user_id
                if !user_id.nil?
                  participant = Participant.find_by_user_id(user_id)
                  participant.update_topic_id(nil)    
                end
             end
            end      
          end
          #signup.destroy
        }
      end
    end
    
    #remove all the sent invitations
    old_invs = Invitation.find(:all, :conditions => ['from_id = ? and assignment_id = ?', @student.user_id, @student.parent_id])
    for old_inv in old_invs
      old_inv.destroy
    end
    
    #reset the participants submission directory to nil
    #per EFG:
    #the participant is responsible for resubmitting their work
    #no restriction is placed on when a participant can leave
    @student.directory_num = nil
    @student.save
    
    redirect_to :controller => 'student_team', :action => 'view' , :id => @student.id
  end
  
  def review
    @assignment = Assignment.find_by_id(params[:assignment_id])
    redirect_to :controller =>'questionnaire', :action => 'view_questionnaire', :id => @assignment.questionnaires.find_by_type('AuthorFeedbackQuestionnaire').id
  end
end
