class TeamRolesController < ApplicationController
  # GET /team_roles
  # GET /team_roles.xml
  def index
    @team_roles = TeamRole.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @team_roles }
    end
  end

  # GET /team_roles/1
  # GET /team_roles/1.xml
  def show

    redirect_to :controller => 'tree_display', :action => 'list'
  #  @team_role = TeamRole.find(params[:id])

  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @team_role }
  #  end
  end

  # GET /team_roles/new
  # GET /team_roles/new.xml
  def new
    @team_role = TeamRole.new
    @all_roles = TeamRole.all
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @team_role }
    end
  end

  # GET /team_roles/1/edit
  def edit
    @team_role = TeamRole.find(params[:id])
  end

  # POST /team_roles
  # POST /team_roles.xml
  def create
    @team_role = TeamRole.new
    @team_role.role_names = params[:team_role][:role_names]

      if @team_role.save
        redirect_to :controller => 'tree_display', :action => 'list'
      else
       render :action => "new"
      end

  end

  # PUT /team_roles/1
  # PUT /team_roles/1.xml
  def update
    @team_role = TeamRole.find(params[:id])
    role_in_roleset = TeamRolesetsMap.find_all_by_team_role_id(params[:id])

    respond_to do |format|
      if role_in_roleset.count <= 0
        if @team_role.update_attributes(params[:team_role])
          format.html { redirect_to(@team_role, :notice => 'TeamRole was successfully updated.') }
          format.xml  { head :ok }
        end
      else
          flash[:notice] = "Role cannot be edited. It is a part of a Roleset"
          format.html { redirect_to :controller => "team_roles", :action => "index" }
          format.xml  { render :xml => @team_role.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /team_roles/1
  # DELETE /team_roles/1.xml
  def destroy
    @team_role = TeamRole.find(params[:id])
    role_in_roleset = TeamRolesetsMap.find_all_by_team_role_id(params[:id])

    respond_to do |format|
      if role_in_roleset.count <= 0
          @team_role.destroy
          format.html { redirect_to(team_roles_url) }
          format.xml  { head :ok }
      else
          flash[:notice] =  'Role cannot be deleted. Its a part of a roleset.'
          format.html { redirect_to (:controller => 'team_roles', :action => 'index')}
          format.xml  { head :ok }
      end
    end
  end
end
