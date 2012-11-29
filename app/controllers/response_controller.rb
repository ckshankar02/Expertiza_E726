class ResponseController < ApplicationController
  helper :wiki
  helper :submitted_content
  helper :file  
  
  def delete
    @response = Response.find(params[:id])
    return if redirect_when_disallowed(@response)

    map_id = @response.map.id
    @response.delete
    redirect_to :action => 'redirection', :id => map_id, :return => params[:return], :msg => "The response was deleted."
  end

  #Determining the current phase and check if a review is already existing for this stage.
  #If so, edit that version otherwise create a new version.

  def rereview
     @map=ResponseMap.find(params[:id])
     get_content
        array_not_empty=0
      @sorted_array=Array.new
      @prev=Response.all
         #get all versions and find the latest version
      for element in @prev
        if(element.map_id==@map.id)
          array_not_empty=1
          @sorted_array << element
        end
      end

     #sort all the available versions in descending order.
      if array_not_empty==1
         @sorted=@sorted_array.sort { |m1,m2|(m1.version_num and m2.version_num) ? m2.version_num <=> m1.version_num : (m1.version_num ? -1 : 1)}
         @largest_version_num=@sorted[0]
         @latest_phase=@largest_version_num.created_at
         due_dates = DueDate.find(:all, :conditions => ["assignment_id = ?", @assignment.id])
         @sorted_deadlines=Array.new
         @sorted_deadlines=due_dates.sort {|m1,m2|(m1.due_at and m2.due_at) ? m1.due_at <=> m2.due_at : (m1.due_at ? -1 : 1)}
         current_time=Time.new.getutc
         #get the highest version numbered review
         next_due_date=@sorted_deadlines[0]

         #check in which phase the latest review was done.
          for deadline_version in @sorted_deadlines
          if(@largest_version_num.created_at < deadline_version.due_at )
            break
          end
         end
         for deadline_time in @sorted_deadlines
           if(current_time < deadline_time.due_at)
             break
           end
         end
      end

         #check if the latest review is done in the current phase.
         #if latest review is in current phase then edit the latest one.
           #else create a new version and update it.

        # editing the latest review
     if(deadline_version.due_at== deadline_time.due_at)
         #send it to edit here
         @header = "Edit"
         @next_action = "update"
         @return = params[:return]
         @response = Response.find_by_map_id_and_version_num(params[:id],@largest_version_num.version_num)
         return if redirect_when_disallowed(@response)
         @modified_object = @response.id
         @map = @response.map
         get_content
         @review_scores = Array.new
         @questions.each{
         | question |
           @review_scores << Score.find_by_response_id_and_question_id(@response.id, question.id)
         }
    #**********************
    # Check whether this is Jen's assgt. & if so, use her rubric
    if (@assignment.instructor_id == User.find_by_name("jace_smith").id) && @title == "Review"
      if @assignment.id < 469
         @next_action = "custom_update"
         render :action => 'custom_response'
     else
         @next_action = "custom_update"
         render :action => 'custom_response_2011'
     end
    else
      # end of special code (except for the end below, to match the if above)
      #**********************

      render :action => 'response'

    end
           #   render :action => 'edit'
     else
        #else create a new version and update it.

          @header = "New"
          @next_action = "create"
          @feedback = params[:feedback]
          @map = ResponseMap.find(params[:id])
          @return = params[:return]
          @modified_object = @map.id
          get_content
          #**********************
          # Check whether this is Jen's assgt. & if so, use her rubric
          if (@assignment.instructor_id == User.find_by_name("jace_smith").id) && @title == "Review"
            if @assignment.id < 469
               @next_action = "custom_create"
               render :action => 'custom_response'
           else
               @next_action = "custom_create"
               render :action => 'custom_response_2011'
           end
          else
            # end of special code (except for the end below, to match the if above)
            #**********************
          render :action => 'response'
          end

       end
  end
  
  def edit
    @header = "Edit"
    @next_action = "update"
    @return = params[:return]
    @response = Response.find(params[:id]) 
    return if redirect_when_disallowed(@response)

#********************* E726 Changes Starts Here ************************************************
    is_role_present = params[:role_info]
    if !is_role_present.nil?
      is_role_present = "YES"
      @role_response = Response.find(params[:review_role_id])
      @reviewed_role = TeamRole.find(params[:role_info])
      @reviewed_role_ques = TeamRoleQuestionnaire.find_by_team_roles_id(@reviewed_role.id)
    else
      is_role_present = "NO"
      @reviewed_role = nil
      @role_response = nil
    end
    @reviewed_student = User.find(params[:reviewed_member])
#********************** E726 Changes Ends Here ************************************************


    @map = @response.map 
    array_not_empty=0
    @sorted_array=Array.new
    @prev=Response.all
    for element in @prev
      if(element.map_id==@map.id)
        array_not_empty=1
        @sorted_array << element
      end
    end
    if array_not_empty==1
      @sorted=@sorted_array.sort { |m1,m2|(m1.version_num and m2.version_num) ? m2.version_num <=> m1.version_num : (m1.version_num ? -1 : 1)}
      @largest_version_num=@sorted[0]
    end
    @response = Response.find_by_map_id_and_version_num(@map.id,@largest_version_num.version_num)
    @modified_object = @response.id          
    get_content    
    @review_scores = Array.new
    @question_type = Array.new
    @questions.each{
      | question |
      @review_scores << Score.find_by_response_id_and_question_id(@response.id, question.id)
      @question_type << QuestionType.find_by_question_id(question.id)
    }

#*********************** E726 Changes Starts Here ********************************
    if !@role_response.nil?
      @role_map = @role_response.map
      role_array_not_empty = 0
      @role_sorted_array = Array.new
      @role_prev = Response.all
      for element in @role_prev
        if(element.map_id==@role_map.id)
          role_array_not_empty = 1
          @role_sorted_array << element
        end
      end
      if role_array_not_empty==1
        @role_sorted = @role_sorted_array.sort { |m1,m2|(m1.version_num and m2.version_num) ? m2.version_num <=> m1.version_num : (m1.version_num ? -1 : 1)}
        @role_largest_version_num = @role_sorted[0]
      end
      @role_response = Response.find_by_map_id_and_version_num(@role_map.id,@role_largest_version_num.version_num)
      @modified_role_object = @role_response.id
      @reviewed_role_ptr = TeamRole.find(params[:role_info].to_i)
      @reviewed_role_ques_ptr = TeamRoleQuestionnaire.find_by_team_roles_id(@reviewed_role_ptr.id)
      get_role_content
      @role_review_scores = Array.new
      @role_question_type = Array.new
      @role_questions.each{
          | question |
        @role_review_scores << Score.find_by_response_id_and_question_id(@role_response.id, question.id)
        @role_question_type << QuestionType.find_by_question_id(question.id)
      }
    end
#************************ E726 Changes Ends Here ********************************

    # Check whether this is a custom rubric
    if @map.questionnaire.section.eql? "Custom"
      @next_action = "custom_update"
      render :action => 'custom_response'
    else
      # end of special code (except for the end below, to match the if above)
      #**********************
      render :action => 'response'
    end
  end
  
  def redirect_when_disallowed(response)
    # For author feedback, participants need to be able to read feedback submitted by other teammates.
    # If response is anything but author feedback, only the person who wrote feedback should be able to see it.
    if response.map.read_attribute(:type) == 'FeedbackResponseMap' && response.map.assignment.team_assignment
      team = response.map.reviewer.team
      unless team.has_user session[:user]
        redirect_to '/denied?reason=You are not on the team that wrote this feedback'
        return true
      end
    else
      return true unless current_user_id?(response.map.reviewer.user_id)
    end
    return false
  end
  
  def update
    @response = Response.find(params[:id])
    return if redirect_when_disallowed(@response)

#**************************** E726 Changes Starts Here ******************************

    is_role_response_present = params[:role_map_id]
    if !is_role_response_present.nil?
      @role_response = Response.find(params[:role_map_id])
    else
      @role_response = nil
    end

#***************************** E726 Changes Ends Here ********************************

    @myid = @response.id
    msg = ""
    begin 
      @myid = @response.id
      @map = @response.map
      @response.update_attribute('additional_comment',params[:review][:comments])
      
      @questionnaire = @map.questionnaire
      questions = @questionnaire.questions
     
     
      params[:responses].each_pair do |k,v|
      
        score = Score.find_by_response_id_and_question_id(@response.id, questions[k.to_i].id)
          if(score == nil)
           score = Score.create(:response_id => @response.id, :question_id => questions[k.to_i].id, :score => v[:score], :comments => v[:comment])
          end
        score.update_attribute('score',v[:score])
        score.update_attribute('comments',v[:comment])
      end

#********************** E726 Changes Starts Here *********************************

      if !@role_response.nil?

        @my_role_response_id = @role_response.id
        @map = @role_response.map
        @role_response.update_attribute('additional_comment',params[:review][:comments])

        @reviewed_role = TeamRole.find(params[:role_reviewed_ptr])
        @reviewed_role_ques = TeamRoleQuestionnaire.find_by_team_roles_id(@reviewed_role.id)
        @role_questionnaire = Questionnaire.find(@reviewed_role_ques.questionnaire_id)
        role_questions = Question.find_all_by_questionnaire_id(@role_questionnaire.id)

        params[:responses_role].each_pair do |k,v|
          role_score = Score.find_by_response_id_and_question_id(@role_response.id, role_questions[k.to_i].id)
          if(role_score == nil)
            role_score = Score.create(:response_id => @role_response.id, :question_id => role_questions[k.to_i].id, :score => v[:score], :comments => v[:comment])
          end
          role_score.update_attribute('score',v[:score])
          role_score.update_attribute('comments',v[:comment])
        end
      end

#********************** E726 Changes Starts Here *********************************
    rescue
      msg = "Your response was not saved. Cause: "+ $!
    end

    begin
       ResponseHelper.compare_scores(@response, @questionnaire)
       ScoreCache.update_cache(@response.id)
    
      msg = "Your response was successfully saved."
    rescue
      msg = "An error occurred while saving the response: "+$!
    end
    redirect_to :controller => 'response', :action => 'saving', :id => @map.id, :return => params[:return], :msg => msg
  end  
  
  def custom_update
    @response = Response.find(params[:id])
    @myid = @response.id
    msg = ""
    begin
      @myid = @response.id
      @map = @response.map
      @response.update_attribute('additional_comment',"")

      @questionnaire = @map.questionnaire
      questions = @questionnaire.questions

      for i in 0..questions.size-1
        score = Score.find_by_response_id_and_question_id(@response.id, questions[i.to_i].id)
        score.update_attribute('comments',params[:custom_response][i.to_s])
      end
    rescue
      msg = "#{@map.get_title} was not saved."
    end

    msg = "#{@map.get_title} was successfully saved."
    redirect_to :controller => 'response', :action => 'saving', :id => @map.id, :return => params[:return], :msg => msg
  end

  def new_feedback
    review = Response.find(params[:id])
    if review
      reviewer = AssignmentParticipant.find_by_user_id_and_parent_id(session[:user].id, review.map.assignment.id)
      map = FeedbackResponseMap.find_by_reviewed_object_id_and_reviewer_id(review.id, reviewer.id)
      if map.nil?
        map = FeedbackResponseMap.create(:reviewed_object_id => review.id, :reviewer_id => reviewer.id, :reviewee_id => review.map.reviewer.id)
      end
      redirect_to :action => 'new', :id => map.id, :return => "feedback"
    else
      redirect_to :back
    end
  end
  
  def view
    @response = Response.find(params[:id])

#****************************** E726 Changes Starts Here *************************

    role_resp_var = params[:role_review_id]
    if !role_resp_var.nil?
      @role_response = Response.find(role_resp_var.to_i)
      @reviewed_role_ptr = TeamRole.find(params[:role_info].to_i)
      @reviewed_role_ques_ptr = TeamRoleQuestionnaire.find_by_team_roles_id(@reviewed_role_ptr.id)
    else
      @role_response = nil
    end

#******************************* E726 Changes Ends Here *************************

    return if redirect_when_disallowed(@response)
    @map = @response.map
    get_content
    @review_scores = Array.new
    @question_type = Array.new
    @questions.each{
      | question |
      @review_scores << Score.find_by_response_id_and_question_id(@response.id, question.id)
      @question_type << QuestionType.find_by_question_id(question.id)
    }

#***************************** E726 Changes Starts Here **************************

    if !role_resp_var.nil?
      @role_map = @role_response.map
      get_role_content
      @role_review_scores = Array.new
      @role_question_type = Array.new
      @role_questions.each{
          | question |
        @role_review_scores << Score.find_by_response_id_and_question_id(@role_response.id, question.id)
        @role_question_type << QuestionType.find_by_question_id(question.id)
      }
    end

#****************************** E726 Changes Ends Here ***************************

  end
  
  def new
    @header = "New"
    @next_action = "create"    
    @feedback = params[:feedback]
    @map = ResponseMap.find(params[:id])
    @return = params[:return]
    @modified_object = @map.id

#************************** E726 Changes Starts Here ***************************

    @modified_role_object = params[:rolemap_id]
    @reviewed_student = User.find(params[:reviewed_member])

    role_present = params[:role_info]

    if !role_present.nil?
      @reviewed_role = TeamRole.find(params[:role_info])
      @reviewed_role_quest = TeamRoleQuestionnaire.find_by_team_roles_id(@reviewed_role.id)
      @role_questionnaire = Questionnaire.find(@reviewed_role_quest.questionnaire_id)
      @role_questions = Question.find_all_by_questionnaire_id(@role_questionnaire.id)
      @role_min = @role_questionnaire.min_question_score
      @role_max = @role_questionnaire.max_question_score
    else
      @reviewed_role = nil
    end

#************************** E726 Changes Ends Here ***************************

    get_content
    #**********************
    # Check whether this is a custom rubric
    if @map.questionnaire.section.eql? "Custom"
      @question_type = Array.new
      @questions.each{
        | question |
        @question_type << QuestionType.find_by_question_id(question.id)
      }
      if !@map.contributor.nil?
        if @map.assignment.team_assignment?
          team_member = TeamsUser.find_by_team_id(@map.contributor).user_id
          @topic_id = Participant.find_by_parent_id_and_user_id(@map.assignment.id,team_member).topic_id
        else
          @topic_id = Participant.find(@map.contributor).topic_id
        end
      end
      if !@topic_id.nil?
        @signedUpTopic = SignUpTopic.find(@topic_id).topic_name
      end
      @next_action = "custom_create"
      render :action => 'custom_response'
    else
      render :action => 'response'
    end
   end
  
  def create
    @map = ResponseMap.find(params[:id])

#******************* E726 Changes Starts Here ********************************

    is_role_based_review = params[:is_role_based]
    if is_role_based_review == "YES"
      @role_map = ResponseMap.find(params[:role_map_id])
      @reviewed_role_ptr = TeamRole.find(params[:role_reviewed_ptr].to_i)
      @reviewed_role_ques_ptr = TeamRoleQuestionnaire.find_by_team_roles_id(@reviewed_role_ptr.id)
    end

#******************* E726 Changes Ends Here ********************************

    @res = 0
    msg = ""
    error_msg = ""
    begin

      #get all previous versions of responses for the response map.
      array_not_empty=0
      @sorted_array=Array.new
      @prev=Response.all
      for element in @prev
        if(element.map_id==@map.id)
          array_not_empty=1
          @sorted_array << element
        end
      end

#*********************** E726 Changes Starts Here *********************************

      array_not_empty = 0
      @sorted_role_array = Array.new
      if is_role_based_review == "YES"
        for element in @prev
          if element.map_id == @role_map.id
            role_array_not_empty = 1
            @sorted_role_array << element
          end
        end
      end

#************************ E726 Changes Ends Here **********************************

      #if previous responses exist increment the version number.
      if array_not_empty==1
         @sorted=@sorted_array.sort { |m1,m2|(m1.version_num and m2.version_num) ? m2.version_num <=> m1.version_num : (m1.version_num ? -1 : 1)}
         @largest_version_num=@sorted[0]
         if(@largest_version_num.version_num==nil)
            @version=1
         else
            @version=@largest_version_num.version_num+1
         end

        #if no previous version is available then initial version number is 1
      else
          @version=1
      end

#**************************** E726 Changes Starts Here ****************************
#if previous responses exist increment the version number.
      if is_role_based_review == "YES"
        if role_array_not_empty == 1
          @sorted_role = @sorted_role_array.sort {|m1,m2|(m1.version_num and m2.version_num) ? m2.version_num <=> m1.version_num : (m1.version_num ? -1 : 1)}
          @largest_role_version_num = @sorted_role[0]
          if @largest_role_version_num.version_num == nil
            @role_version = 1
          else
            @role_version = @largest_role_version_num.version_num + 1
          end
        else
          @role_version = 1
        end
      end

#***************************** E726 Changes Ends Here *****************************
        @response = Response.create(:map_id => @map.id, :additional_comment => params[:review][:comments],:version_num=>@version)
      @res = @response.id

      # E726 Fall2012 Changes Begin
      @assignment = @map.assignment
      @participant = @map.reviewer
      if @participant.special_role == "Reader"
        @questionnaire = Questionnaire.find(@assignment.readerreview_questionnaire_id)
        questions = Question.find_all_by_questionnaire_id(@assignment.readerreview_questionnaire_id)
      elsif @participant.special_role == "Manager"
        @questionnaire = Questionnaire.find(@assignment.managerreview_questionnaire_id)
        questions = Question.find_all_by_questionnaire_id(@assignment.managerreview_questionnaire_id)
      else
        @questionnaire = @map.questionnaire
        questions = @questionnaire.questions
      end
      # E726 Fall2012 Changes End

      params[:responses].each_pair do |k,v|
        score = Score.create(:response_id => @response.id, :question_id => questions[k.to_i].id, :score => v[:score], :comments => v[:comment])
      end

#********************** E726 Changes Starts Here ***********************************
#The review scores are captured by the below code on to the score table.
      if is_role_based_review == "YES"
        @role_response = Response.create(:map_id => @role_map.id, :additional_comment => params[:review_role][:comments],:version_num=>@role_version)
        @role_res = @role_response.id
        @role_questionnaire = Questionnaire.find(@reviewed_role_ques_ptr.questionnaire_id)
        role_questions = Question.find_all_by_questionnaire_id(@role_questionnaire.id)
        params[:responses_role].each_pair do |k,v|
          score = Score.create(:response_id => @role_response.id, :question_id => role_questions[k.to_i].id, :score => v[:score], :comments => v[:comment])
        end
      end

#*********************** E726 Changes Ends Here ***********************************

    rescue
      error_msg = "Your response was not saved. Cause: " + $!
    end
    
    begin
      ResponseHelper.compare_scores(@response, @questionnaire)
      ScoreCache.update_cache(@res)
      @map.save
      msg = "Your response was successfully saved."

#********************** E726 Changes Starts Here ********************************
# For the role based review made a score cache entry is made.
      if is_role_based_review == "YES"
        ResponseHelper.compare_scores(@role_response, @role_questionnaire)
        ScoreCache.update_cache(@role_res)
        @role_map.save
        msg = "Your response was successfully saved."
      end
#*********************** E726 Changes Ends Here *********************************

    rescue
      @response.delete

#*********************** E726 Changes Starts Here *******************************

      if is_role_based_review == "YES"
        @role_response.delete
      end

#************************ E726 Changes Ends Here ********************************

      error_msg = "Your response was not saved. Cause: " + $!
    end
    redirect_to :controller => 'response', :action => 'saving', :id => @map.id, :return => params[:return], :msg => msg, :error_msg => error_msg
  end

  #E726 Fall2012 Changes Begin
  def selfreview_create
    id=ResponseMap.create(:reviewed_object_id => params[:locals][:assignment_id], :reviewer_id => params[:locals][:user_id],
                       :reviewee_id => params[:locals][:user_id], :type => "SelfReviewResponseMap")
    @map = ResponseMap.find(id)
    @response = Response.create(:map_id => @map.id, :additional_comment => params[:review][:comments])
    for i in 0..params[:locals][:questions].size-1
      # Local variable score is unused; can it be removed?
      score = Score.create(:response_id => @response.id, :question_id => params[:locals][:questions][i],
                           :score => params[:responses][i.to_s][:score].to_i, :comments => params[:responses][i.to_s][:comment])
    end
    msg = "Self Review was successfully saved."
    redirect_to :controller => 'submitted_content', :action => 'edit', :id => @map.reviewer.id
  end

  def selfreview_update
    response_id = Response.find_by_map_id(params[:locals][:response_map_id])
    response_id.update_attribute('additional_comment', params[:review][:comments])

    scores = Score.find_all_by_response_id(response_id.id)

    for i in 0..scores.size-1
      scores[i].update_attribute('score', params[:responses][i.to_s][:score].to_i)
      scores[i].update_attribute('comments', params[:responses][i.to_s][:comment])
    end

    response_map = ResponseMap.find(params[:locals][:response_map_id])
    redirect_to :controller => 'submitted_content', :action => 'edit', :id => response_map.reviewer_id
  end

  #E726 Fall2012 Changes End

  def custom_create
    @map = ResponseMap.find(params[:id])
    @response = Response.create(:map_id => @map.id, :additional_comment => "")
    @res = @response.id
    @questionnaire = @map.questionnaire
    questions = @questionnaire.questions
    
    for i in 0..questions.size-1
        # Local variable score is unused; can it be removed?
        score = Score.create(:response_id => @response.id, :question_id => questions[i].id, :score => @questionnaire.max_question_score, :comments => params[:custom_response][i.to_s])
          

    end
    msg = "#{@map.get_title} was successfully saved."
    
    redirect_to :controller => 'response', :action => 'saving', :id => @map.id, :return => params[:return], :msg => msg
  end

  def saving   
    @map = ResponseMap.find(params[:id])
    @return = params[:return]
    @map.notification_accepted = false;
    puts("saving for me ")
    puts(params[:id]);
    @map.save
    
    redirect_to :action => 'redirection', :id => @map.id, :return => params[:return], :msg => params[:msg], :error_msg => params[:error_msg]
  end
  
  def redirection
    flash[:error] = params[:error_msg] unless params[:error_msg] and params[:error_msg].empty?
    flash[:note]  = params[:msg] unless params[:msg] and params[:msg].empty?
    
    @map = ResponseMap.find(params[:id])
    if params[:return] == "feedback"
      redirect_to :controller => 'grades', :action => 'view_my_scores', :id => @map.reviewer.id
    elsif params[:return] == "teammate"
      redirect_to :controller => 'student_team', :action => 'view', :id => @map.reviewer.id
    elsif params[:return] == "instructor"
      redirect_to :controller => 'grades', :action => 'view', :id => @map.assignment.id
    else
      redirect_to :controller => 'student_review', :action => 'list', :id => @map.reviewer.id
    end 
  end
  
  private
    
  def get_content    
    @title = @map.get_title 
    @assignment = @map.assignment
    @participant = @map.reviewer
    @contributor = @map.contributor
    # E726 Fall2012 Changes Begin
    if @participant.special_role == "Reader"
      @questionnaire = Questionnaire.find(@assignment.readerreview_questionnaire_id)
      @questions = Question.find_all_by_questionnaire_id(@assignment.readerreview_questionnaire_id)
    elsif @participant.special_role == "Manager"
      @questionnaire = Questionnaire.find(@assignment.managerreview_questionnaire_id)
      @questions = Question.find_all_by_questionnaire_id(@assignment.managerreview_questionnaire_id)
    else
      @questionnaire = @map.questionnaire
      @questions = @questionnaire.questions
    end
    # E726 Fall2012 Changes End
    @min = @questionnaire.min_question_score
    @max = @questionnaire.max_question_score
  end

#************************** E726 Changes Starts Here *************************
  def get_role_content
    @role_title = @role_map.get_title
    @role_assignment = @role_map.assignment
    @role_participant = @role_map.reviewer
    @role_contributor = @role_map.contributor
    @role_res = @role_response.id

    @role_questionnaire = Questionnaire.find(@reviewed_role_ques_ptr.questionnaire_id)
    @role_questions = Question.find_all_by_questionnaire_id(@role_questionnaire.id)
    @role_min = @role_questionnaire.min_question_score
    @role_max = @role_questionnaire.max_question_score

  end
#*************************** E726 Changes Ends Here ***************************

  def redirect_when_disallowed(response)
    # For author feedback, participants need to be able to read feedback submitted by other teammates.
    # If response is anything but author feedback, only the person who wrote feedback should be able to see it.
    if response.map.read_attribute(:type) == 'FeedbackResponseMap' && response.map.assignment.team_assignment
      team = response.map.reviewer.team
      unless team.has_user session[:user]
        redirect_to '/denied?reason=You are not on the team that wrote this feedback'
        return true
      end
    else
      return true unless current_user_id?(response.map.reviewer.user_id)
    end
    return false
  end
end
