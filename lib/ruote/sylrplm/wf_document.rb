require 'ruote/participant'
require 'openwfe/participants/participants'

class Ruote::WfDocument

  include OpenWFE::LocalParticipant
  #
  # By default, returns false. When returning true the dispatch to the
  # participant will not be done in his own thread.
  def do_not_thread
    true
  end

  def initialize(work=nil, opts=nil)
    puts "WfTest.initialize*******************************************"
    puts "WfTest.initialize:opts="+opts.nil?.to_s+" work="+work.inspect
    @opts = opts
  end

  def consume(workitem)
    puts "WfTest.consume*******************************************"
    puts "WfTest.consume:workitem="+workitem.inspect
    puts "WfTest.consume:opts="+@opts.nil?.to_s
    #puts "WfTest.consume:params="+workitem.attributes["params"].inspect
    unless workitem.attributes.nil?
      unless workitem.attributes["params"].nil?
        task = workitem.attributes["params"]["task"]
        relation = workitem.attributes["params"]["relation"] unless workitem.attributes["params"]["relation"].nil?
      end
    end
    puts "WfTest.consume:task="+task+" relation="+relation.to_s
    fexpid=workitem.flow_expression_id
    #puts "WfTest.consume:instance_id:"+fexpid.workflow_instance_id
    #puts "WfTest.consume:expression_id:"+fexpid.expression_id
    arworkitem = OpenWFE::Extras::ArWorkitem.find_by_wfid(fexpid.workflow_instance_id)
    if(task=="promote_init" || task=="promote_review" )
      unless relation.nil?
        #prise en compte des objets transmis par le ar_workitem
        unless arworkitem.field_hash.nil?
          params= arworkitem.field_hash["params"]
          puts "WfTest.consume:params="+params.inspect
          params.keys.each do |k|
            params.keys.sort.each do |k|
              #puts "WfTest.consume:key=#{k.inspect} => #{params[k].inspect}"
              sp=k.split("/")
              #puts "WfTest.consume:sp=#{sp.inspect} => #{k.inspect}"
              if sp.size==3 && sp[0]!=k
                #puts "WfTest.consume:"+sp[1]+"("+sp[1].size.to_s+"):"+sp[2]
                cls=sp[1].chop
                id=sp[2]
                #puts "WfTest.consume:cls=#{cls.inspect} id=#{id.inspect}"
                link=add_object(arworkitem, cls, id, relation)
                puts "WfTest.consume:link="+link.inspect
              end
            end

          end
        end
      else
        puts "WfTest.consume: pas de relation=> abandon"
        get_engine.cancel_process(fexpid)
      end

    elsif(task=="promote_exec")
      puts "WfTest.consume: promote_exec"
      Link.find_childs("history",arworkitem,"document").each do |link|
        obj=Document.find(link.child_id)
        #puts "WfTest.consume:promote_exec:"+obj.to_s
        obj.promote
        obj.save
        puts "WfTest.consume:promote_exec:"+obj.to_s
      end
      Link.find_childs("history",arworkitem,"part").each do |link|
        obj=Part.find(link.child_id)
        #puts "WfTest.consume:promote_exec:"+obj.to_s
        obj.promote
        obj.save
        puts "WfTest.consume:promote_exec:"+obj.to_s
      end

      #      fields["/document/1"]=""
      #      arworkitem.replace_fields(fields)
      #      puts "WfTest.consume:fields="+arworkitem.field_hash.inspect
      #      arworkitem.save!

      #      params=workitem.attributes["params"]
      #      params["/document/1"]=""
      #      workitem.set_attribute("params",params)
      #      puts "WfTest.consume:workitem="+workitem.inspect
      #puts "WfTest.consume:fin de promote"
    end
    reply_to_engine (workitem)
  end

  def add_object(workitem, type_object, item_id, relation)
    #      puts "WfTest.add_object:workitem="+workitem.id.to_s+" rel="+relation.inspect+" favori="+favori.inspect
    link_=Link.create_new_byid("workitem", workitem.id, type_object, item_id, relation)
    link=link_[:link]
    if(link!=nil)
      unless link.save
      link_=nil
      end
    end
    #puts  "WfTest.add_object:"+link_.inspect
    link_
  end

  #
  #
  #
  def add_objects(workitem, favori, type_object, relation)
    ret=0
    unless favori.nil?
      msg=""
      #      puts "processes_controller.add_objects:workitem="+workitem.id.to_s+" rel="+relation.inspect+" favori="+favori.inspect
      favori.items.each do |item|
        link_=Link.create_new_byid("workitem", workitem.id, type_object, item.id, relation)
        link=link_[:link]
        if(link!=nil)
          if(link.save)
            msg += "\nLink added:"+type_object+":"+item.ident+"-"+relation+":"+link_[:msg]
          ret+=1
          else
            msg += "\nLink not saved:"+type_object+":"+item.ident+"-"+relation+":"+link_[:msg]
          end
        else
          msg += "\nLink not added:"+type_object+":"+item.ident+"-"+relation
        end
      end
    #reset_favori_document
    else
      msg = "\nNothing to link:"+type_object
    end
    puts  "WfTest.consume:"+type_object+"="+ret.to_s+":"+msg
    ret
  end

end
