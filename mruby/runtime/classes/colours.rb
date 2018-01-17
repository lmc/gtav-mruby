class RGBA < Struct.new(:r,:g,:b,:a)

  def hsva
    HSVA.new( HSV.rgb_to_hsv(r,g,b) , a )
  end
  
  def _inspect
    "RGBA(#{self.to_a.inspect[1...-1]})"
  end

  def rgb
    [r,g,b]
  end

  def to_s
    inspect
  end
end

def RGBA(*args)
  RGBA.new(*args)
end


class HSVA < Struct.new(:h,:s,:v,:a)

  def rgba
    RGBA.new( HSVA.hsv_to_rgb(h,s,v) , a )
  end

  # https://gist.github.com/makevoid/3918299
  # http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically
  def self.hsv_to_rgb(h, s, v)
    h, s, v = h.to_f/360, s.to_f/100, v.to_f/100
    h_i = (h*6).to_i
    f = h*6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f) * s)
    r, g, b = v, t, p if h_i==0
    r, g, b = q, v, p if h_i==1
    r, g, b = p, v, t if h_i==2
    r, g, b = p, q, v if h_i==3
    r, g, b = t, p, v if h_i==4
    r, g, b = v, p, q if h_i==5
    [(r*255).to_i, (g*255).to_i, (b*255).to_i]
  end
  # http://ntlk.net/2011/11/21/convert-rgb-to-hsb-hsv-in-ruby/
  def self.rgb_to_hsv(r, g, b)
    r = r / 255.0
    g = g / 255.0
    b = b / 255.0
    max = [r, g, b].max
    min = [r, g, b].min
    delta = max - min
    v = max * 100
    if (max != 0.0)
      s = delta / max * 100
    else
      s = 0.0
    end
    if (s == 0.0)
      h = 0.0
    else
      if (r == max)
        h = (g - b) / delta
      elsif (g == max)
        h = 2 + (b - r) / delta
      elsif (b == max)
        h = 4 + (r - g) / delta
      end
      h *= 60.0
      if (h < 0)
        h += 360.0
      end
    end
    [h, s, v]
  end
end

def HSVA(*args)
  HSVA.new(*args)
end

