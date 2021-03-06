require 'erb'

def protect_against_forgery?
end

def protect_against_forgery
end

class Node
	DEFAULT_OPTIONS={
		:label=> "Click Here",
		:url =>"#",
		:title => '',
		:target  => '',
		:icon  => '',
		:icon_open  => '',
		:event_name  => 'href',
		:open => true,
		:parent => '',
		:id => '',
		:link_to_remote => nil,
		:link_to => nil,
		#syl
		:js_name => 'r',
		:obj_child => nil,
		:link => nil,
		:quantity => nil
	}

	include ActionView::Helpers::UrlHelper
	include ActionView::Helpers::PrototypeHelper
	include ActionView::Helpers::JavaScriptHelper
	include ERB::Util

	DEFAULT_OPTIONS.keys.each do |method_name|
		define_method method_name do
			@options[method_name]
		end
		define_method "#{method_name}=" do |value|
			@options[method_name] = value
		end
	end

	def initialize(options={},html_options={},&block)
		@nodes=[]
		@options = DEFAULT_OPTIONS.merge(options)

		@id=options[:id] || self.object_id.abs
		if options[:link_to_remote]
			internal_link_to_remote(@label,options[:link_to_remote] , html_options)
		end

		if options[:link_to]
			internal_link_to(@label,options[:link_to] , *html_options.to_a)
		end
		block.call(@nodes) if block
	end

	def <<(node)
		@nodes << node
	end

	def id
		return @id || self.object_id.abs
	end

	def child(options={},html_options={})
		case options
		when Node
			@nodes << options
		when Hash
			n=Node.new(options,html_options)
			yield n if block_given?
			self.child(n)
			return n
		else
		raise Exception.new("Unknow arguments #{node.class}")
		end
	end

	def internal_link_to(name, options = {}, *parameters_for_method_reference)

		@url="#{url_formater(options,parameters_for_method_reference)}"
		@label=name

	end

	def internal_link_to_remote(name, options = {}, html_options ={})
		@controller=options[:base]
		options.delete :base
		@request=@controller.request
		@label=name
		@event_name='onclick'
		@url=remote_function(options)
	end

	def nodes
		if block_given?
		yield @nodes
		else
		@nodes
		end
	end

	#syl
	def nodes=(new_nodes)
		@nodes=new_nodes
	end

	#syl
	def label=(new_label)
		@options[:label] = new_label
	end

	def id
		@options[:id]
	end

	def obj_child
		@options[:obj_child]
	end

	def link
		@options[:link]
	end

	def quantity
		@options[:quantity]
	end

	def quantity=(new_quantity)
		@options[:quantity] = new_quantity
	end

	def equals?(other_node)
		fname="Node:#{__method__}"
		#LOG.debug(fname){"#{other_node.obj_child} equals?(#{self.obj_child})"}
		unless self.obj_child.nil? ||  other_node.obj_child.nil?
			ret = self.obj_child.ident == other_node.obj_child.ident
			if ret == false
			ret = self.label == other_node.label
			end
		end
		#LOG.debug(fname){"#{other_node.obj_child.ident} == #{self.obj_child.ident} = #{ret}"} if ret
		ret
	end

	def size
		@nodes.size
	end

	#syl pour la somme des noeuds de l'arbre
	def size_all
		fname="Node:#{__method__}"
		ret=0
		ret=self.size_all_(ret, 0)
		ret
	end

	def size_all_(ret, level)
		fname="Node:#{__method__}"
		#LOG.debug(fname){"==>level=#{level}, nodes:#{nodes.size}, ret=#{ret}"}
		level+=1
		nodes.each do |nod|
			ret= 1+ nod.size_all_(ret, level)
		end
		#LOG.debug(fname){"<==level=#{level}, ret=#{ret}"}
		ret
	end

	def to_s
		#syl @nodes.to_s
		"#{@nodes.count}:#{@nodes}"
	end

	private

	def url_formater(options,parameters_for_method_reference)
		if options.is_a? Hash
			begin
				@controller=options[:base]
				options.delete :base
				@request=@controller.request
			rescue => e
				options="Controller not found #{e}"
			end
		end
		options.is_a?(String) ? options : url_for(options, *parameters_for_method_reference)
	end

end
