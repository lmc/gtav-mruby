
class PersistentHash

  def initialize(filename,defaults_filename = nil,prefix = nil)
    @filename = filename
    @defaults_filename = defaults_filename
    @defaults_prefix = prefix
    @hash = {}
    @metadata = {}
    load_from_file(true)
    load_from_file(false)
  end

  def [](key)
    @hash.key?(key) ? @hash[key] : (@metadata[key] && @metadata[key][:default])
  end

  def []=(key,value)
    @hash[key] = value
    @metadata[key] = {} if !@metadata[key]
    @metadata[key][:changed] = true
  end

  def size
    @hash.size
  end

  def delete(key)
    @hash.delete(key)
  end

  def load_from_file(defaults = false)
    begin
      filename = defaults && @defaults_filename ? @defaults_filename : @filename
      io = File.new(filename,"r")
      data = io.read()
      # log "data: #{data}"
      buffer = ""
      return if !data
      data.lines.each do |line|
        sline = line.strip
        if sline[0] == "#" || sline.size == 0
          buffer << line
        else
          state = :begin
          values = { state => "" }
          sline.chars.each_with_index do |c,i|
            if c == "[" && state == :begin
              state = :key
              next
            elsif c == "]" && state == :key
              state = :assign
            elsif c == "=" && state == :assign
              state = :assign2
              next
            elsif c != " " && state == :assign2
              state = :value
            end
            if state != :assign && state != :assign2
              values[state] = "" if !values[state]
              values[state] << c
            end
          end

          if values[:key][0] == '"' && values[:key][-1] == '"'
            values[:key] = values[:key][1..-2]
          end
          
          value = values[:value]
          value = GTAV.is_syntax_valid?(value) ? eval(value) : nil
          if defaults
            @metadata[ values[:key] ] = {default: value, default_buffer: buffer}
            @defaults_prefix = values[:begin] if !@defaults_prefix && values[:begin].size > 0
          else
            @hash[ values[:key] ] = value
            @metadata[ values[:key] ] = {} if !@metadata[ values[:key] ]
            @metadata[ values[:key] ][:matches] = values
            @metadata[ values[:key] ][:buffer] = buffer
          end
          buffer = ""
        end
      end
      io.close rescue nil
    rescue IOError
      nil
    ensure
      io.close if io rescue nil
    end
  end

  def write_to_file
    puts "write_to_file  "
    # TODO: make saves atomic
    begin
      io = File.new(@filename,"w")
      @hash.keys.sort_by{|k|
        s = k.split(".")#[1].to_i rescue 0
        s[1] = s[1].to_i rescue s[1]
        s
      }.each do |key|
        value = @hash[key]
        if !@metadata[key]
          log "no metadata for #{key.inspect}"
        end
        if @metadata[key][:changed]
          value = persist_value(value)
        else
          value = @metadata[key][:matches][:value]
        end
        io.print @metadata[key][:buffer]
        k = @defaults_prefix
        k = @metadata[key][:matches][:begin] if @metadata[key][:matches]
        io.puts "#{k}[#{key.inspect}] = #{value}"
      end
      io.close
    rescue IOError
      nil
    ensure
      io.close if io rescue nil
    end
  end
  
  def list_size(prefix,member)
    i = 0
    while list_value(prefix,i,member)
      i += 1
    end
    i
  end
  
  def list_values(prefix,i,members = [])
    hash = {}
    members.each do |member|
      hash[member] = list_value(prefix,i,member)
    end
    hash
  end

  def list_value(prefix,index,member)
    self["#{prefix}.#{index}.#{member}"]
  end

  def list_delete(prefix,index,members)
    size = list_size(prefix,members[0])
    members.each{|member| self.delete("#{prefix}.#{index}.#{member}") }
    index.upto(size - 1) do |i|
      members.each{|member|
        self["#{prefix}.#{i}.#{member}"] = self["#{prefix}.#{i + 1}.#{member}"]
       }
    end
    members.each{|member| self.delete("#{prefix}.#{size - 1}.#{member}") }
  end

  def each_list(prefix,members = [],&block)
    array = []
    j = list_size(prefix,members[0])
    0.upto(j - 1) do |i|
      hash = list_values(prefix,i,members)
      block_given? ? yield(hash,i) : array.push(hash)
    end
    array
  end

  def persist_value(value)
    case value
    when Float
      value = value.inspect
      value == "0" ? "0.0" : value
    else
      value.inspect
    end
  end

  def to_hash
    @hash.dup
  end

end

