class String
  def ends_with?(val)
    self =~ /#{Regexp.escape val}\Z/
  end
  
  def starts_with?(val)
    self =~ /\A#{Regexp.escape val}/
  end
end

class Fixnum
  def to_c_str
    back = ''
    back << self
    back
  end
end

module XML
  class InvalidCDATAError < RuntimeError; end
  
  class XMLBuilder
    attr_reader :indent_increment
    attr_writer :indent_increment
    
    private
    def initialize(indent='', indent_increment='  ', write_preamble=true)
      @indent = indent
      @indent_increment = indent_increment
      
      @value = ''
      self.write_preamble = write_preamble
    end
    
    public
    def method_missing(sym, *args, &block)
      @value += "\n" unless @value.strip == ''

      if sym.to_s == 'mod'
        sym = 'module'
      end

      @value += "#{@indent}<#{element_escape sym.to_s}"
      
      unless args.empty?
        args[0].each do |key, value|
          @value += " #{key.to_s}=\"#{text_escape value.to_s}\""
        end
      end
      
      block = args[-1] if block.nil? and !args.empty?
      
      if block.is_a? Proc    # more flexible than block_given?
        @value += ">"
        
        builder = XMLBuilder.new(@indent + @indent_increment, @indent_increment, false)
        block_value = builder.instance_eval(&block).to_s
        
        @value += "\n" + builder.to_s + "\n" unless builder.to_s.strip == ''
        
        #unless @value.ends_with? block_value
        #  block_value = text_escape block_value \
        #    unless block_value.strip.starts_with? '<![CDATA[' and block_value.strip.ends_with?  ']]>'
        #  block_value = line_break(block_value).join("\n#{@indent + @indent_increment}")

        unless @value.ends_with? block_value
          @value += "\n" + @indent + @indent_increment if block_value.strip.size > 30
          @value += block_value
          @value += "\n" + @indent if block_value.strip.size > 30
        else
          @value += @indent
        end
        
         @value += "</#{element_escape sym.to_s}>"
      else
        @value += '/>'
      end
    end
    alias_method :element, :method_missing
    
    def write_preamble?
      @write_preamble
    end
    
    def write_preamble=(val)
      if val and @value.strip == ''
        @value = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      elsif !val and @value.strip == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        @value = ''
      end
      @write_preamble = val
    end
    
    def clear
      if @write_preamble
        @value = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      else
        @value = ''
      end
    end
    
    def cdata(str)
      raise XML::InvalidCDATAError, 'CDATA text cannot contain "]]>"' if str =~ /#{Regexp.escape ']]>'}/
      
      '<![CDATA[' + str + ']]>'
    end
    
    def text_escape(str)
      back = ''
      str.each_byte do |c|
        case c
          when '<'[0]
            back += '&lt;'
          when '>'[0]
            back += '&gt;'
          when '&'[0]
            back += '&amp;'
          when "'"[0]
            back += '&apos;'
          when '"'[0]
            back += '&quot;'
          else
            back += c.to_c_str
        end
      end
      back
    end
  
    def line_break(str, max_width=60)
      back = []
      line = ''
      push = proc { back.push line.strip }
      
      str.each ' ' do |word|
        if line.size + word.size > max_width
          push.call
          line = ''
        end
        
        line += word
      end
      push.call
      
      back
    end
    
    def element_escape(str)
      str = str[3..(str.size - 1)] if str.downcase.starts_with? 'xml'
      str
    end
    
    def to_s
      @value
    end
    
    def self.instance
      @@instance ||= new
    end
  end
end

def xml
  XML::XMLBuilder.instance
end
