
class UiTable < Struct.new(:x, :y, :w, :h, :rh, :widths, :data, :p, :pco, :pci, :pro, :pri, :cell_text, :header_row_text, :body_row_text, :tr, :tg, :tb, :ta, :cr, :cg, :cb, :ca)
  def initialize(options = {})
    self.x      = options[:x]      || 0.3
    self.y      = options[:y]      || 0.3
    self.w      = options[:w]      || 0.3
    self.h      = options[:h]      || 0.3
    self.rh     = options[:rh]     || nil
    self.widths = options[:widths] || [ 1.0 ]
    self.data   = options[:data]   || [ ["UiTable"] ]
    self.p      = options[:p]      || 0.01
    self.pco    = options[:pco]    || 0.01
    self.pci    = options[:pci]    || 0.01
    self.pro    = options[:pro]    || 0.01
    self.pri    = options[:pri]    || 0.0
    self.tr     = options[:tr]     || 255
    self.tg     = options[:tg]     || 255
    self.tb     = options[:tb]     || 255
    self.ta     = options[:ta]     || 127
    self.cr     = options[:cr]     || 0
    self.cg     = options[:cg]     || 0
    self.cb     = options[:cb]     || 0
    self.ca     = options[:ca]     || 127
    self.cell_text = options[:cell_text] || UiStyledText.new(font: 4, scale2: 1.3)
    self.header_row_text = options[:header_row_text] || nil
    self.body_row_text = options[:body_row_text] || nil
  end
  def draw
    sx = 1080.0 / 1920.0
    dx = x + (p * sx)
    dy = y + p
    rows = data.size || 1
    cols = data[0].size || 1
    if rh
      drh = rh
      self.h = (p * 2) + (rh * rows) + (pro * rows) - pro
    else
      drh = ((h - (p * 2) - (rows * pro) + pro) / rows)
    end
    if ta != 0
      GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, tr,tg,tb,ta)
    end
    data.each_with_index do |row,ri|
      row.each_with_index do |column,ci|
        cw = ((widths[ci] || 0.0) * (w - (p * 2 * sx) - ((pco * sx) * cols) + (pco * sx) ))
        xl = dx + (sx * pci)
        xr = dx + cw - (sx * pci)
        if ca != 0
          GRAPHICS::DRAW_RECT(dx + (cw / 2), dy + (drh / 2), cw, drh, cr,cg,cb,ca)
        end
        raise "nope" if !self.text_class_for(ri,ci,column)
        self.text_class_for(ri,ci,column).draw(data[ri][ci] || "",xl,dy + pri,xl,xr)
        dx += cw + (pco * sx)
      end
      dy += drh + pro
      dx = x + (p * sx)
    end
  end
  def text_class_for(ri,ci,val)
    if ri == 0
      header_row_text || cell_text
    else
      body_row_text || cell_text
    end
  end
end

