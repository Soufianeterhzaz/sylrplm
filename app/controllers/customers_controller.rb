require 'lib/controllers/plm_object_controller_module'
require 'lib/controllers/plm_init_controller_module'
class CustomersController < ApplicationController
  include PlmObjectControllerModule
  include PlmInitControllerModule
  before_filter :check_init, :only=>[:new]
  
  access_control (Access.find_for_controller(controller_class_name()))
  
  # GET /customers
  # GET /customers.xml
  def index
    sort=params['sort']
    conditions = ["ident LIKE ? or "+qry_type+" or designation LIKE ? or "+qry_status+
      " or "+qry_owner+" or date LIKE ? ",
      "#{params[:query]}%", "#{params[:query]}%", 
    "#{params[:query]}%", "#{params[:query]}%", 
    "#{params[:query]}%", "#{params[:query]}%" ] unless params[:query].nil? 
    @query="#{params[:query]}"
    @total=Customer.count( :conditions => conditions)
#    @customers = Customer.paginate(:page => params[:page], 
#          :conditions => conditions,
#          :order => sort,
#          :per_page => cfg_items_per_page)
          
    @customers = Customer.find_paginate({:page=>params[:page],:cond=>conditions,:sort=>params[:sort], :nbr=>cfg_items_per_page}) 
          
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @customers }
    end
  end
  
  # GET /customers/1
  # GET /customers/1.xml
  def show
    @customer = Customer.find(params[:id])
    @relation_types_document=Typesobject.getTypesNames(:relation_document)
    @relation_types_project=Typesobject.getTypesNames(:relation_project)
    @tree=create_tree(@customer)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @customer }
    end
  end
  
  # GET /customers/new
  # GET /customers/new.xml
  def new
    @customer = Customer.create_new(nil,@user)
    @types=Typesobject.getTypes(:customer)
    @status= Statusobject.find_for(:customer)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @customer }
    end
  end
  
  # GET /customers/1/edit
  def edit
    @customer = Customer.find_edit(params[:id])
    @types=Typesobject.getTypes(:customer)
    @status= Statusobject.find_for(:customer)
  end
  
  # POST /customers
  # POST /customers.xml
  def create
    @customer = Customer.create_new(params[:customer],@user)
    @types=Typesobject.getTypes(:customer)
    @status= Statusobject.find_for(:customer)
    respond_to do |format|
      if @customer.save
        flash[:notice] = t(:ctrl_object_created,:object=>t(:ctrl_customer),:ident=>@customer.ident)
        format.html { redirect_to(@customer) }
        format.xml  { render :xml => @customer, :status => :created, :location => @customer }
      else
        flash[:notice] = t(:ctrl_object_not_created,:object=>t(:ctrl_customer))
        format.html { render :action => :new }
        format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /customers/1
  # PUT /customers/1.xml
  def update
    @customer = Customer.find(params[:id])
    @types=Typesobject.getTypes(:customer)
    @status= Statusobject.find_for(:customer)
    respond_to do |format|
      if @customer.update_attributes(params[:customer])
        flash[:notice] = t(:ctrl_object_updated,:object=>t(:ctrl_customer),:ident=>@customer.ident)
        format.html { redirect_to(@customer) }
        format.xml  { head :ok }
      else
        flash[:notice] = t(:ctrl_object_notupdated,:object=>t(:ctrl_customer),:ident=>@customer.ident)
        format.html { render :action => :edit }
        format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /customers/1
  # DELETE /customers/1.xml
  def destroy
    @customer = Customer.find(params[:id])
    @customer.destroy
    flash[:notice] = t(:ctrl_object_deleted,:object=>t(:ctrl_customer),:ident=>@customer.ident)
    respond_to do |format|
      format.html { redirect_to(customers_url) }
      format.xml  { head :ok }
    end
  end
  
  
  def remove_project
    @project = Project.find(params[:id])
    @customer = Customer.find(@project.customer)
    @customer.remove_project(@project)
    if(@customer.save)
      flash[:notice] = t(:ctrl_remove_project_ok,:project=>@project.ident,:object=>@customer.ident)
    else
      flash[:notice] = t(:ctrl_remove_project_ko,:project=>@project.ident,:object=>@customer.ident)
    end
  end
  
  def create_tree(obj)
    tree = Tree.new({:label=>t(:ctrl_object_explorer,:object=>t(:ctrl_customer)),:open => true})   
    #cnode = tree_customer(obj)    
    #tree << cnode
    session[:tree_object]=obj
    follow_tree_customer(tree, obj,self)
    tree
  end
  
  def add_docs
    @customer = Customer.find(params[:id])
    relation=params[:relation][:document]
    respond_to do |format|      
      if @favori_document != nil 
        flash[:notice] = ""
        @favori_document.items.each do |item|
          #flash[:notice] += "<br>"+ item.ident.to_s
          link_=Link.create_new(:customer, @customer, :document, item, relation)  
          link=link_[:link]
          if(link!=nil) 
            if(link.save)
              flash[:notice] += t(:ctrl_object_added,:object=>t(:ctrl_document),:ident=>item.ident,:relation=>relation,:msg=>t(link_[:msg]))
            else
              flash[:notice] += t(:ctrl_object_not_added,:object=>t(:ctrl_document),:ident=>item.ident,:relation=>relation,:msg=>t(link_[:msg]))
            end
          else
            flash[:notice] += t(:ctrl_object_not_linked,:object=>t(:ctrl_document),:ident=>item.ident,:relation=>relation,:msg=>nil)           
          end        end
        reset_favori_document
      else
        flash[:notice] = t(:ctrl_nothing_to_paste,:object=>t(:ctrl_document))
      end
      format.html { redirect_to(@customer) }
      format.xml  { head :ok }
    end
  end   
  
  def add_projects
    @customer = Customer.find(params[:id])
    relation=params[:relation][:project]
    respond_to do |format|      
      if @favori_project != nil 
        flash[:notice] = ""
        @favori_project.items.each do |item|
          link_=Link.create_new(:customer, @customer, :project, item, relation)  
          link=link_[:link]
          if(link!=nil) 
            if(link.save)
              flash[:notice] += t(:ctrl_object_added,:object=>t(:ctrl_project),:ident=>item.ident,:relation=>relation,:msg=>t(link_[:msg]))
            else
              flash[:notice] += t(:ctrl_object_not_added,:object=>t(:ctrl_project),:ident=>item.ident,:relation=>relation,:msg=>t(link_[:msg]))
            end
          else
            flash[:notice] += t(:ctrl_object_not_linked,:object=>t(:ctrl_project),:ident=>item.ident,:relation=>relation,:msg=>nil)           
          end
          
        end
        reset_favori_project
      else
        flash[:notice] = t(:ctrl_nothing_to_paste,:object=>t(:ctrl_project))
      end
      format.html { redirect_to(@customer) }
      format.xml  { head :ok }
    end
  end   
  
  def promote
    ctrl_promote(Customer,false)
  end
  
  def demote
    ctrl_demote(Customer,false)
  end
  
  def new_forum
    puts 'CustomerController.new_forum:id='+params[:id]
    @object = Customer.find(params[:id])
    @types=Typesobject.find_for("forum")
    @status= Statusobject.find_for("forum")
    respond_to do |format|      
      flash[:notice] = ""
      @forum=Forum.create_new(nil)
      @forum.subject=t(:ctrl_subject_forum,:object=>t(:ctrl_customer),:ident=>@object.ident)
      format.html {render :action=>:new_forum, :id=>@object.id }
      format.xml  { head :ok }
    end
  end 
  
  def add_forum
    @object = Customer.find(params[:id])
    ctrl_add_forum(@object,"customer")
  end
end
