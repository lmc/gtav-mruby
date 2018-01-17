
class GTAV::BoxedObjectInt
  def ==(other)
    return self[0] == other[0] if other.is_a?(GTAV::BoxedObjectInt)
    return self[0] == other if other.is_a?(Numeric)
    super
  end
end

class Fixnum
  def ==(other)
    return self == other[0] if other.is_a?(GTAV::BoxedObjectInt)
    super
  end
end
