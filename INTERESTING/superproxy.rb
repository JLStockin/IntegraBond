class SuperProxy
  def initialize(obj)
    @obj = obj
  end

  def method_missing(meth, *args, &blk)
    @obj.class.superclass.instance_method(meth).bind(@obj).call(*args, &blk)
  end
end

class Transaction
  private
  def sup
    SuperProxy.new(self)
  end
end