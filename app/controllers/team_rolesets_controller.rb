class TeamRolesetsController < ApplicationController
  # GET /team_rolesets
  # GET /team_rolesets.xml
  def index
    @team_rolesets = TeamRoleset.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @team_rolesets }
    end
  end

  # GET /team_rolesets/1
  # GET /team_rolesets/1.xml
  def show
    @team_roleset = TeamRoleset.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @team_roleset }
    end
  end

  # GET /team_rolesets/new
  # GET /team_rolesets/new.xml
  def new
    @all_team_roles = TeamRole.all
    @team_roleset = TeamRoleset.new
=begin
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @team_roleset }
    end
=end
  end

  # GET /team_rolesets/1/edit
  def edit
    @team_roleset = TeamRoleset.find(params[:id])
  end

  # POST /team_rolesets
  # POST /team_rolesets.xml
  def create
    @team_roleset = TeamRoleset.new
    @team_roleset.roleset_name = params[:roleset_name]
      if @team_roleset.save
        role_count = params[:numRolesToAdd]

        i = 0
        while i < role_count.to_i do
          if !params[:role_select]["#{i}"].nil?
            team_rolesets_map = TeamRolesetsMap.new
            team_rolesets_map.team_role_id = params[:role_select]["#{i}"]
            team_rolesets_map.team_rolesets_id = @team_roleset.id
            team_rolesets_map.save
            i = i+1
          end
        end

        redirect_to :controller => 'tree_display', :action => 'list'
      else
        render :action => "new"
      end
  end

  # PUT /team_rolesets/1
  # PUT /team_rolesets/1.xml
  def update
    @team_roleset = TeamRoleset.find(params[:id])

    respond_to do |format|
      if @team_roleset.update_attributes(params[:team_roleset])
        format.html { redirect_to(@team_roleset, :notice => 'TeamRoleset was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @team_roleset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /team_rolesets/1
  # DELETE /team_rolesets/1.xml
  def destroy
    @team_roleset = TeamRoleset.find(params[:id])
    rolesets_in_map = TeamRolesetsMap.find_all_by_team_rolesets_id(params[:id])

    rolesets_in_map.each do |x|
      x.destroy
    end

    @team_roleset.destroy

    respond_to do |format|
      format.html { redirect_to(team_rolesets_url) }
      format.xml  { head :ok }
    end
  end
end
