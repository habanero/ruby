# リファクタリング Ruby にあるコード

module Assertions
  class AssertionFaildError < StandardError; end

  def assert(&condition)
    raise AssertionFaildError.new("Assertion Failed") unless condition.call
  end
end

# 本番環境ではassertで何もしない
=begin
Assertions.class_eval do
  def assert; end;
end
=end

if __FILE__ == $0
  class Foo
    include Assertions
    def true_method
      assert{ true }
    end

    def false_method
      assert{ false }
    end
  end

  f = Foo.new
  f.true_method  #=> not raised
  f.false_method #=> raise AssertionFaildError
end