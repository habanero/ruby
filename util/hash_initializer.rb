#  リファクタリング Rubyエディション にあったコード

module HashInitializer
  def hash_initializer(*attribute_names)
    define_method(:initialize) do |*args|
      data = args.first || {}
      attribute_names.each do |attribute_name|
        instance_variable_set("@#{attribute_name}", data[attribute_name])
      end
    end
  end
end

Class.__send__(:include, HashInitializer)

if __FILE__ == $0
  class A
    hash_initializer :attr1, :attr2
  end

  a = A.new(:attr1 => "attr1", :attr2 => "attr2")
  a.instance_eval do
    p @attr1
    p @attr2
  end
end