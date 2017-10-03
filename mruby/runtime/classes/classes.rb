
class GTAV::BoxedObject
  def inspect
    "#{self.class.to_s.gsub("GTAV::","")}(#{self.map{|i| i.inspect}.join(", ")})"
  end
  def to_s
    inspect
  end
end

class GTAV::BoxedObjectInt
  def to_i; self[0]; end
end

class GTAV::Vector3
  def x; self[0]; end
  def y; self[1]; end
  def z; self[2]; end
  def x=(v); self[0] = v; end
  def y=(v); self[1] = v; end
  def z=(v); self[2] = v; end
end

module GTAV
  @@boot_time = Time.now.to_i

  def self.time
    time = Time.now
    sec,usec = time.to_i, time.usec
    sec -= @@boot_time
    (sec.to_i * 1000) + (usec / 1000).to_i
  end

  def self.time_usec
    time = Time.now
    sec,usec = time.to_i, time.usec
    sec -= @@boot_time
    sec.to_f + (usec.to_f / 1000000.0)
  end

end

def enum_to_hash(enum)
  hash = {}
  enum.constants.each do |key|
    hash[ enum.const_get(key) ] = key.to_s
  end
  hash
end


class PersistentHash

  def initialize(filename,defaults_filename = nil)
    @filename = filename
    @defaults_filename = defaults_filename
    @defaults_prefix = nil
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

  def load_from_file(defaults = false)
    begin
      filename = defaults ? @defaults_filename : @filename
      io = File.new(filename,"r")
      data = io.read()
      # log "data: #{data}"
      buffer = ""
      data.lines.each do |line|
        sline = line.strip
        if sline[0] == "#" || sline.size == 0
          buffer << line
        else
          state = :begin
          values = {}
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
      io.close
    rescue IOError
      nil
    end
  end

  def write_to_file
    begin
      io = File.new(@filename,"w")
      @hash.each_pair do |key,value|
        if !@metadata[key]
          log "no metadata for #{key.inspect}"
        end
        if @metadata[key][:changed]
          value = value.inspect
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
    end
  end

end

