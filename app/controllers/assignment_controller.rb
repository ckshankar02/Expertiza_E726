class AssignmentController < ApplicationController

  auto_complete_for :user, :name
  before_filter :authorize

  def copy
    Assignment.record_timestamps = false
    #creating a copy of an assignment; along with the dates and submission directory too
    old_assign = Assignment.find(params[:id])
    new_assign = old_assign.clone
    @user =  ApplicationHelper::get_user_role(session[:user])
    @user = session[:user]
    @user.set_instructor(new_assign)
    new_assign.update_attribute('name','Copy of '+new_assign.name)
    new_assign.update_attribute('created_at',Time.now)
    new_assign.update_attribute('updated_at',Time.now)



    if new_assign.save
      Assignment.record_timestamps = true

      old_assign.assignment_questionnaires.each do |aq|
        AssignmentQuestionnaire.create(
            :assignment_id => new_assign.id,
            :questionnaire_id => aq.questionnaire_id,
            :user_id => session[:user].id,
            :notification_limit => aq.notification_limit,
            :questionnaire_weight => aq.questionnaire_weight
        )
      end

      DueDate.copy(old_assign.id, new_assign.id)
      new_assign.create_node()

      flash[:note] = 'Warning: The submission directory for the copy of this assignment will be the same as the submission directory for the existing assignment, which will allow student submissions to one assignment to overwrite submissions to the other assignment.  If you do not want this to happen, change the submission directory in the new copy of the assignment.'
      redirect_to :action => 'edit', :id => new_assign.id
    else
      flash[:error] = 'The assignment was not able to be copied. Please check the original assignment for missing information.'
      redirect_to :action => 'list', :controller => 'tree_display'
    end
  end

  def new

    #creating new assignment and setting default values using helper functions
    if params[:parent_id]
      @course = Course.find(params[:parent_id])
    end

    @assignment = Assignment.new

    @wiki_types = WikiType.find(:all)
    @private = params[:private] == true
    #calling the defalut values mathods
    get_limits_and_weights

#**************** E726 Changes Starts Here *************************************
    @all_team_rolesets = TeamRoleset.all
    @all_team_roles = TeamRole.all
#***************** E726 Changes Ends Here ***************************************

  end


  # Toggle the access permission for this assignment from public to private, or vice versa
  def toggle_access
    assignment = Assignment.find(params[:id])
    assignment.private = !assignment.private
    assignment.save

    redirect_to :controller => 'tree_display', :action => 'list'
  end

  def create
    # The Assignment Directory field to be filled in is the path relative to the instructor's home directory (named after his user.name)
    # However, when an administrator creates an assignment, (s)he needs to preface the path with the user.name of the instructor whose assignment it is.

    # E726 Fall2012 Changes Begin
    # Code for adding rubrics if option selected in the form was "Same as Review Rubric"
    if(params[:selfreview_checkbox] == "selfreview_checkbox")
      params[:questionnaires][:selfreview] = params[:questionnaires][:review]
      params[:weights][:selfreview] = params[:weights][:review]
      params[:limits][:selfreview] = params[:limits][:review]
    end
    if(params[:managerreview_checkbox] == "managerreview_checkbox")
      params[:questionnaires][:managerreview] = params[:questionnaires][:review]
      params[:weights][:managerreview] = params[:weights][:review]
      params[:limits][:managerreview] = params[:limits][:review]
    end
    if(params[:readerreview_checkbox] == "readerreview_checkbox")
      params[:questionnaires][:readerreview] = params[:questionnaires][:review]
      params[:weights][:readerreview] = params[:weights][:review]
      params[:limits][:readerreview] = params[:limits][:review]
    end
    # E726 Fall2012 Changes End
#******************************** E726 Changes Starts Here ***************************
    is_team_assignment = params[:assignment][:team_assignment]
    is_roleset_selected = params[:roleset_selection_status]
    is_role_selected = params[:role_selection_status]
#********************************* E726 Changes Ends Here ****************************

    @assignment = Assignment.new(params[:assignment])
    @user =  ApplicationHelper::get_user_role(session[:user])
    @user = session[:user]
    @user.set_instructor(@assignment)
    @assignment.submitter_count = 0
    ## feedback added
    ##

    if params[:days].nil? && params[:weeks].nil?
      @days = 0
      @weeks = 0
    elsif params[:days].nil?
      @days = 0
    elsif params[:weeks].nil?
      @weeks = 0
    else
      @days = params[:days].to_i
      @weeks = params[:weeks].to_i
    end


    @assignment.days_between_submissions = @days + (@weeks*7)

    # Deadline types used in the deadline_types DB table
    deadline = DeadlineType.find_by_name("submission")
    @Submission_deadline = deadline.id
    deadline = DeadlineType.find_by_name("review")
    @Review_deadline = deadline.id
    deadline = DeadlineType.find_by_name("resubmission")
    @Resubmission_deadline = deadline.id
    deadline = DeadlineType.find_by_name("rereview")
    @Rereview_deadline = deadline.id
    deadline = DeadlineType.find_by_name("metareview")
    @Review_of_review_deadline = deadline.id
    deadline = DeadlineType.find_by_name("drop_topic")
    @drop_topic_deadline = deadline.id

    check_flag = @assignment.availability_flag
    # E726 Fall2012 Changes Begin
=begin
    # Assigning the Rubric Ids to the fields present in Assignments table
    @assignment.review_questionnaire_id = params[:questionnaires][:review].to_i
    @assignment.review_of_review_questionnaire_id = params[:questionnaires][:metareview].to_i
    @assignment.teammate_review_questionnaire_id = params[:questionnaires][:teammate].to_i
    @assignment.author_feedback_questionnaire_id = params[:questionnaires][:feedback].to_i
=end
    @assignment.selfreview_questionnaire_id = params[:questionnaires][:selfreview].to_i
    @assignment.managerreview_questionnaire_id = params[:questionnaires][:managerreview].to_i
    @assignment.readerreview_questionnaire_id = params[:questionnaires][:readerreview].to_i
    # E726 Fall2012 Changes End

    if(check_flag == true && params[:submit_deadline].nil?)
      raise "Please enter a valid Submission deadline!!"
      render :action => 'create'
    elsif (@assignment.save)


#***************************** E726 Changes Starts Here ******************************
      if is_team_assignment == "true"
        if is_roleset_selected == "yes"
           params[:team_rolesets].each do |x|
              if x.to_i != 0
                 roles_of_roleset = TeamRolesetsMap.find_all_by_team_rolesets_id(x.to_i)
                 roles_of_roleset.each do |y|
                    teamrole_assignment_entry = TeamroleAssignment.new
                    teamrole_assignment_entry.team_role_id = y.team_role_id
                    teamrole_assignment_entry.assignment_id = @assignment.id
                    teamrole_assignment_entry.save
                 end
              end
           end
        end
        if is_role_selected == "yes"
          params[:team_roles].each do |x|
            if x.to_i != 0
               teamrole_assignment_entry = TeamroleAssignment.new
               teamrole_assignment_entry.team_role_id = x.to_i
               teamrole_assignment_entry.assignment_id = @assignment.id
               teamrole_assignment_entry.save
            end
          end
        end
      end
#****************************** E726 Changes Ends Here ********************************

      set_questionnaires
      set_limits_and_weights
      max_round = 1
      begin
        #setting the Due Dates with a helper function written in DueDate.rb
        if check_flag == true
          due_date = DueDate::set_duedate(params[:submit_deadline],@Submission_deadline, @assignment.id, max_round )
          raise "Please enter a valid Submission deadline" if !due_date
        else
          due_date = DueDate::set_duedate(params[:submit_deadline],@Submission_deadline, @assignment.id, max_round )
        end
        due_date = DueDate::set_duedate(params[:review_deadline],@Review_deadline, @assignment.id, max_round )
#        raise "Please enter a valid Review deadline" if !due_date
        max_round = 2;

        due_date = DueDate::set_duedate(params[:drop_topic_deadline],@drop_topic_deadline, @assignment.id, 0)
#       raise "Please enter a valid Drop-Topic deadline" if !due_date

        if params[:assignment_helper][:no_of_reviews].to_i >= 2
          for resubmit_duedate_key in params[:additional_submit_deadline].keys
            #setting the Due Dates with a helper function written in DueDate.rb
            due_date = DueDate::set_duedate(params[:additional_submit_deadline][resubmit_duedate_key],@Resubmission_deadline, @assignment.id, max_round )
            raise "Please enter a valid Resubmission deadline" if !due_date
            max_round = max_round + 1
          end
          max_round = 2
          for rereview_duedate_key in params[:additional_review_deadline].keys
            #setting the Due Dates with a helper function written in DueDate.rb
            due_date = DueDate::set_duedate(params[:additional_review_deadline][rereview_duedate_key],@Rereview_deadline, @assignment.id, max_round )
            raise "Please enter a valid Rereview deadline" if !due_date
            max_round = max_round + 1
          end
        end
#setting the Due Dates with a helper function written in DueDate.rb
        @assignment.questionnaires.each{
            |questionnaire|
          if questionnaire.instance_of? MetareviewQuestionnaire
            due_date = DueDate::set_duedate(params[:reviewofreview_deadline],@Review_of_review_deadline, @assignment.id, max_round )
            raise "Please enter a valid Metareview deadline" if !due_date
          end
        }

        # Create submission directory for this assignment
        # If assignment is a Wiki Assignment (or has no directory)
        # the helper will not create a path
        FileHelper.create_directory(@assignment)

        # Creating node information for assignment display
        @assignment.create_node()

        flash[:alert] = "There is already an assignment named \"#{@assignment.name}\". &nbsp;<a style='color: blue;' href='../../assignment/edit/#{@assignment.id}'>Edit assignment</a>" if @assignment.duplicate_name?
        flash[:note] = 'Assignment was successfully created.'
        redirect_to :action => 'list', :controller => 'tree_display'
      rescue
        flash[:error] = $!
        prepare_to_edit
        @wiki_types = WikiType.find(:all)
        render :action => 'new'
      end

    else
      @wiki_types = WikiType.find(:all)
      render :action => 'new'
    end

  end

  def edit
    @assignment = Assignment.find(params[:id])
    @prev_review_topic_threshold = @assignment.review_topic_threshold
    prepare_to_edit
  end

  def prepare_to_edit
    if !@assignment.days_between_submissions.nil?
      @weeks = @assignment.days_between_submissions/7
      @days = @assignment.days_between_submissions - @weeks*7
    else
      @weeks = 0
      @days = 0
    end

    get_limits_and_weights
    @wiki_types = WikiType.find(:all)
  end

  def define_instructor_notification_limit(assignment_id, questionnaire_id, limit)
    existing = NotificationLimit.find(:first, :conditions => ['user_id = ? and assignment_id = ? and questionnaire_id = ?',session[:user].id,assignment_id,questionnaire_id])
    if existing.nil?
      NotificationLimit.create(:user_id => session[:user].id,
                               :assignment_id => assignment_id,
                               :questionnaire_id => questionnaire_id,
                               :limit => limit)
    else
      existing.limit = limit
      existing.save
    end
  end

  def set_questionnaires
    @assignment.questionnaires = Array.new
    #raise params[:questionnaires].to_s
    params[:questionnaires].each{
        | key, value |
      if value.to_i > 0 and (q = Questionnaire.find(value))
        @assignment.questionnaires << q
      end
    }
  end

  def get_limits_and_weights
    @limits = Hash.new
    @weights = Hash.new

    if session[:user].role.name == "Teaching Assistant"
      user_id = Ta.get_my_instructor(session[:user]).id
    else
      user_id = session[:user].id
    end

    default = AssignmentQuestionnaire.find_by_user_id_and_assignment_id_and_questionnaire_id(user_id,nil,nil)

    if default.nil?
      default_limit_value = 15
    else
      default_limit_value = default.notification_limit
    end

    @limits[:review]     = default_limit_value
    @limits[:metareview] = default_limit_value
    @limits[:feedback]   = default_limit_value
    @limits[:teammate]   = default_limit_value
    # E726 Fall2012 Changes Begin
    @limits[:selfreview]   = default_limit_value
    @limits[:managerreview]   = default_limit_value
    @limits[:readerreview]   = default_limit_value
    # E726 Fall2012 Changes Begin

    @weights[:review] = 100
    @weights[:metareview] = 0
    @weights[:feedback] = 0
    @weights[:teammate] = 0
    # E726 Fall2012 Changes Begin
    @weights[:selfreview]   = 100
    @weights[:managerreview]   = 100
    @weights[:readerreview]   = 100
    # E726 Fall2012 Changes End

    @assignment.questionnaires.each{
        | questionnaire |
      aq = AssignmentQuestionnaire.find_by_assignment_id_and_questionnaire_id(@assignment.id, questionnaire.id)
      @limits[questionnaire.symbol] = aq.notification_limit
      @weights[questionnaire.symbol] = aq.questionnaire_weight
    }
  end

  def set_limits_and_weights
    if session[:user].role.name == "Teaching Assistant"
      user_id = TA.get_my_instructor(session[:user]).id
    else
      user_id = session[:user].id
    end

    default = AssignmentQuestionnaire.find_by_user_id_and_assignment_id_and_questionnaire_id(user_id,nil,nil)
    @assignment.questionnaires.each{
        | questionnaire |
      aq = AssignmentQuestionnaire.find_by_assignment_id_and_questionnaire_id(@assignment.id, questionnaire.id)
      if params[:limits][questionnaire.symbol].length > 0
        aq.update_attribute('notification_limit',params[:limits][questionnaire.symbol])
      else
        aq.update_attribute('notification_limit',default.notification_limit)
      end
      aq.update_attribute('questionnaire_weight',params[:weights][questionnaire.symbol])
      aq.update_attribute('user_id',user_id)
    }
  end

  def update
    if params[:assignment][:course_id]
      begin
        Course.find(params[:assignment][:course_id]).copy_participants(params[:id])
      rescue
        flash[:error] = $!
      end
    end
    @assignment = Assignment.find(params[:id])
    begin
      oldpath = @assignment.get_path
    rescue
      oldpath = nil
    end

    if params[:days].nil? && params[:weeks].nil?
      @days = 0
      @weeks = 0
    elsif params[:days].nil?
      @days = 0
    elsif params[:weeks].nil?
      @weeks = 0
    else
      @days = params[:days].to_i
      @weeks = params[:weeks].to_i
    end


    @assignment.days_between_submissions = @days + (@weeks*7)

    # The update call below updates only the assignment table. The due dates must be updated separately.
    if @assignment.update_attributes(params[:assignment])
      if params[:questionnaires] and params[:limits] and params[:weights]
        set_questionnaires
        set_limits_and_weights
      end
      # E726 Fall2012 Change Begin
      # update the reviews_rem field of participants and team table only if the topic threshold has changed
      if params[:prev_review_topic_threshold].to_i != @assignment.review_topic_threshold
        teams = Team.find_all_by_parent_id(@assignment.id)
        teams.each do |team|
          team.reviews_rem = @assignment.review_topic_threshold
          team.save
        end
        participants = Participant.find_all_by_parent_id(@assignment.id)
        participants.each do |participant|
          participant.reviews_rem = @assignment.review_topic_threshold
          participant.save
        end
      end
      # E726 Fall2012 Change Begin

      begin
        newpath = @assignment.get_path
      rescue
        newpath = nil
      end
      if oldpath != nil and newpath != nil
        FileHelper.update_file_location(oldpath,newpath)
      end

      begin
        # Iterate over due_dates, from due_date[0] to the maximum due_date
        if params[:due_date]
          for due_date_key in params[:due_date].keys
            due_date_temp = DueDate.find(due_date_key)
            due_date_temp.update_attributes(params[:due_date][due_date_key])
            raise "Please enter a valid date & time" if due_date_temp.errors.length > 0
          end
        end

        flash[:notice] = 'Assignment was successfully updated.'
        redirect_to :action => 'show', :id => @assignment

      rescue
        flash[:error] = $!
        prepare_to_edit
        render :action => 'edit', :id => @assignment
      end
    else # Simply refresh the page
      @wiki_types = WikiType.find(:all)
      render :action => 'edit'
    end
  end

  def show
    @assignment = Assignment.find(params[:id])
  end

  def delete
    assignment = Assignment.find(params[:id])

    # If the assignment is already deleted, go back to the list of assignments
    if assignment
      begin
        @user = session[:user]
        id = @user.get_instructor
        if(id != assignment.instructor_id)
          raise "Not authorised to delete this assignment"
        end
        assignment.delete(params[:force])
        @a = Node.find(:first, :conditions => ['node_object_id = ? and type = ?',params[:id],'AssignmentNode'])

        @a.destroy
        flash[:notice] = "The assignment is deleted"
      rescue
        url_yes = url_for :action => 'delete', :id => params[:id], :force => 1
        url_no  = url_for :action => 'delete', :id => params[:id]
        error = $!
        flash[:error] = error.to_s + " Delete this assignment anyway?&nbsp;<a href='#{url_yes}'>Yes</a>&nbsp;|&nbsp;<a href='#{url_no}'>No</a><BR/>"
      end
    end

    redirect_to :controller => 'tree_display', :action => 'list'
  end

  def list
    set_up_display_options("ASSIGNMENT")
    @assignments=super(Assignment)
    #    @assignment_pages, @assignments = paginate :assignments, :per_page => 10
  end

  def associate_assignment_to_course
    @assignment = Assignment.find(params[:id])
    @user =  ApplicationHelper::get_user_role(session[:user])
    @user = session[:user]
    @courses = @user.set_courses_to_assignment
  end

  def remove_assignment_from_course
    assignment = Assignment.find(params[:id])
    oldpath = assignment.get_path rescue nil
    assignment.course_id = nil
    assignment.save
    newpath = assignment.get_path rescue nil
    FileHelper.update_file_location(oldpath,newpath)
    redirect_to :controller => 'tree_display', :action => 'list'
  end
end
