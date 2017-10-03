
class UiBarChart < Struct.new(:x, :y, :w, :h, :p, :limits, :bw, :data)
  def initialize(options = {})
    self.x         = options[:x]      || 0.33
    self.y         = options[:y]      || 0.33
    self.w         = options[:w]      || 0.33
    self.h         = options[:h]      || 0.33
    self.p         = options[:p]      || 0.01
    self.limits    = options[:limits] || [0.0,1.0]
    self.bw        = options[:bw]     || 0.0033
    self.data      = options[:data]   || []
  end
  def draw
    ct = y
    cb = y + h
    dw = (bw * data.size)
    ym = limits[1]
    GRAPHICS::DRAW_RECT(x + (dw / 2.0) - (bw / 2.0),ct + (h / 2.0) + 0.005,dw,h,0,0,0,127)

    data.each_with_index do |d,i|
      val = (d + 0.0) / ym
      if d > ym
        r,g,b,a = 255,0,0,127
      elsif d >= 0.004
        r,g,b,a = 255,255,0,127
      else
        r,g,b,a = 0,255,0,127
      end
      dh = ct + (val * h)
      dy = cb - (val * (h * 0.5))
      GRAPHICS::DRAW_RECT(x + (bw * i),dy,bw,dh,r,g,b,a)
    end
  end
end

