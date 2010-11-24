require 'net/http'
require "lib/controllers/plm_object_controller_module"
class DatafilesController < ApplicationController
  include PlmObjectControllerModule
  # GET /datafiles
  # GET /datafiles.xml
  def index
    sort=params['sort']
    @query="#{params[:query]}" 
    conditions = ["ident LIKE ? or "+qry_type+" or revision LIKE ? "+
      " or "+qry_owner+" or updated_at LIKE ? or "+qry_volume,
      "#{params[:query]}%", 
    "#{params[:query]}%", "#{params[:query]}%", 
    "#{params[:query]}%", "#{params[:query]}%", 
    "#{params[:query]}%", "#{params[:query]}%" ] unless params[:query].nil?
    #@total=Datafile.count( :conditions => conditions)
    @total=Datafile.count
    @datafiles = Datafile.paginate(:page => params[:page], 
      :conditions => conditions,
      :order => sort,
      :per_page => cfg_items_per_page)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @datafiles }
    end
  end
  
  # GET /datafiles/1
  # GET /datafiles/1.xml
  def show
    @datafile = Datafile.find(params[:id])
    @types=Typesobject.find_for("datafile")
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @datafile }
    end
  end
  
  # GET /datafiles/new
  # GET /datafiles/new.xml
  def new
    @datafile = Datafile.createNew(nil, @user)
    @types=Typesobject.find_for("datafile")
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @datafile }
    end
  end
  
  # GET /datafiles/1/edit
  def edit
    @datafile = Datafile.find(params[:id])
    @types=Typesobject.find_for("datafile")
  end
  
  # POST /datafiles
  # POST /datafiles.xml
  def create
    @datafile = Datafile.createNew(params, @user)
    @types=Typesobject.find_for("datafile")
    puts "datafiles_controller.create:errors="+@datafile.errors.inspect
    respond_to do |format|
      if @datafile
        flash[:notice] = t(:ctrl_object_created,:object=>t(:ctrl_datafile),:ident=>@datafile.ident)
        format.html { redirect_to(@datafile) }
        format.xml  { render :xml => @datafile, :status => :created, :location => @datafile }
      else
        flash[:notice] = t(:ctrl_object_not_created,:object=>t(:ctrl_datafile))
        format.html { render :action => "new" }
        format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /datafiles/1
  # PUT /datafiles/1.xml
  def update
    @datafile = Datafile.find(params[:id])
    @types=Typesobject.find_for("datafile")
    respond_to do |format|
      if @datafile.update_attributes_repos(params[:datafile],@user)
        flash[:notice] = t(:ctrl_object_updated,:object=>t(:ctrl_datafile),:ident=>@datafile.ident)
        format.html { redirect_to(@datafile) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_not_updated,:object=>t(:ctrl_datafile),:ident=>@datafile.ident)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @datafile.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /datafiles/1
  # DELETE /datafiles/1.xml
  def destroy
    @datafile = Datafile.find(params[:id])
    @datafile.destroy
    @types=Typesobject.find_for("datafile")
    respond_to do |format|
      format.html { redirect_to(datafiles_url) }
      format.xml  { head :ok }
    end
  end
  
  def show_file
    @datafile = Datafile.find(params[:id])
    send_data(@datafile.readFile,
        :filename=>@datafile.filename,
        :type=>@datafile.content_type,
        :disposition=>"inline")    
  end
  
  def download_file
    @datafile = Datafile.find(params[:id])
    send_data(@datafile.readFile,
      :filename=>@datafile.filename,
      :type=>@datafile.content_type,
      :disposition=>"attachment")   
    return @datafile.filename 
  end
  
  def show_file_data
    @datafile = Datafile.find(params[:id])
    send_data(@datafile.data,
      :filename=>@datafile.filename,
      :type=>@datafile.content_type,
      :disposition=>"inline")    
  end
  
end
