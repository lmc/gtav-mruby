class File < IO
  def self.open(*args, &block)
    f = self.new(*args)

    return f unless block

    begin
      yield f
    ensure
      f.close
    end
  end

  def <<(obj)
    write(obj.class == String ? obj : obj.to_s)
  end

  def getc
    read(1)
  end

  def putc(c)
    write(c[0])
    c[0]
  end

  def print(*args)
    args.each {|s| write s.to_s}
    nil
  end

  def puts(*args)
    args.each {|v|
      s = v.to_s
      write s
      write "\n" unless s[-1] == "\n"
    }
    nil
  end

  # def printf(format, *args)
  #   write sprintf(format, *args)
  #   nil
  # end

  def pos=(offset)
    seek(offset, IO::SEEK_SET)
  end
end
