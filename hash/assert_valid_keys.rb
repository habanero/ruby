#  リファクタリング Rubyエディション にあったコード

module AssertValidKeys
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - [valid_keys].flatten
    if unknown_keys.any?
      raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(', ')}")
    end
  end
end

Hash.__send__(:include, AssertValidKeys)

if __FILE__ == $0
  h = {:key1 => 1, :key2 => 2, :key3 => 3}
  # not raise
  h.assert_valid_keys :key1, :key2, :key3
  h.assert_valid_keys :key1, :key2, :key3, :foobar

  # raise
  h.assert_valid_keys :key1
end