require 'nokogiri'
require 'byebug'

class Doc

  attr_accessor :formats, :block_tag, :inline_tag, :root, :line

  VOID_TAGS = [:AREA, :BASE, :BR, :COL, :COMMAND, :EMBED, :HR, :IFRAME, :IMG, :INPUT, :KEYGEN, :LINK, :META, :PARAM, :SOURCE, :TRACK, :WBR]

  def initialize(formats = {}, options = {})
    @line = nil
    @formats = formats
    @block_tag = options[:block_tag] || 'div'
    @inline_tag = options[:inline_tag] || 'span'
    @root = Nokogiri::HTML::DocumentFragment.parse("<root></root>")
  end

  def self.convert(delta, formats, options = {})
    doc = new(formats, options)
    delta[:ops].each { |op| doc.write_op(op) }
    doc.get_html.gsub("\n", '')
  end

  def get_html
    @root.at_css('root').inner_html
  end

  def write_op(op)
    raise StandardError, 'Cannot convert delta with non-insert operations' if op[:insert].nil?

    attrs = op[:attributes] || {}
    text = op[:insert].is_a?(String) ? op[:insert].gsub("\r\n", "\n") : '!'
    index = text.index("\n")
    
    while !index.nil?
      write_text(text.slice(0, index), attrs)
      format_line(attrs)
      @line = nil
      text = text.slice(index + 1, text.length)
      index = text.nil? ? nil : text.index("\n")
    end

    if text.length > 0
      write_text(text, attrs)
    end
  end

  def write_text(text, attrs)
    if @line.nil?
      @line = Nokogiri::XML::Node.new @block_tag, @root
      @root.at_css('root') << @line
    end

    return if text.length == 0

    node = Nokogiri::XML::Text.new(text, @root)

    if attrs.empty?
      @line << node
    end

    attrs.each do |k, v|
      if format = @formats[k] and format[:type] != 'line'
        node = apply_format(node, format, v)

        if node.text? && node.parent
          # this feels hacky, but is intended to replace line with the node's parent
          @line.replace(node.parent)
        else
          @line << node
        end
      end 
    end

    @line = @root.at_css('root').children.last
  end

  def apply_format(node, format, value)
    if tag = format[:tag]
      if format[:type] == 'line'
        node.name = tag
      else
        # WTF is void tag? not sure what this is even doing
        if VOID_TAGS.include?(tag)
          node = Nokogiri::XML::Node.new tag, @root
        else
          # wrap node with wrapper
          wrapper = Nokogiri::XML::Node.new tag, @root
          wrapper.inner_html = node.to_html
          node = wrapper
        end
      end
    end

    if tag = format[:parent_tag]
      # do this once only
      if node.previous.nil? || node.previous.name != tag
        wrapper = Nokogiri::XML::Node.new tag, @root
        wrapper << node # node is now removed from root
        root.at_css('root') << wrapper
      end

      if node.previous && node.previous.name == tag
        node.previous << node
      end
    end

    if format[:attribute] || format[:class] || format[:style]
      # if is text node
      if node.text?
        parent = Nokogiri::XML::Node.new(@inline_tag, @root)
        parent << node
        node = parent
      end

      if format[:attribute]
        node[format[:attribute]] = value
      end

      if klass = format[:class]
        node[:class] = (node[:class] || '') << "#{klass}#{value}"
      end

      if style = format[:style]
        node[:style] = (node[:style] || '') << "#{style}: #{value}; "
      end
    end

    # currently does not work
    if fn = format[:add]
      node = fn.call(node, value)
    end

    node
  end

  # TKTK
  def format_line(attrs)
    line = @line

    attrs.each do |k, v|
      if format = @formats[k] and format[:type] == 'line'
        line = apply_format(line, format, v)
      end  
    end

    @line = line
  end

end
