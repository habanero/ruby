
require 'monitor'

class TaggedQueue
  def initialize
    @monitor = Monitor.new
    @any_cv = @monitor.new_cond
    @tag_cv = {}
    @queue = []
  end

  def enq(value, tag=value.class)
    @monitor.synchronize do
      @queue.push([tag, value])
      cv = @tag_cv[tag] and cv.signal
      @any_cv.signal
    end
    self
  end

  def deq(tag=nil)
    if tag.nil?
      @monitor.synchronize do
        @any_cv.wait_while{ @queue.empty? }
        pair = @queue.shift
        return pair.last
      end
    else
      @monitor.synchronize do
        unless i = find_tag(tag)
          cv = (@tag_cv[tag] ||= @monitor.new_cond)
          cv.wait_until{ i = find_tag(tag) }
        end
        pair = @queue.delete_at(i)
        return pair.last
      end
    end
  end

  private
  def find_tag(tag)
    @queue.each_with_index do |pair, i|
      return i if pair.first == tag
    end
    return nil
  end
end


if __FILE__ == $0
  queue = TaggedQueue.new
  generators = {
    Fixnum => lambda{ rand(10)},
    String  => lambda{ (10+rand(26)).to_s(36).upcase }
  }

  types = generators.keys

  generators.each do |type, func|
    Thread.start do
      puts "#{type} producer starts"
      loop {
        sleep rand(3)
        value = func.call
        puts "#{type} producer enqueing #{value}"
        queue.enq(value)
      }
    end
  end

  Thread.start do
    puts "General consumer starts"
    loop {
      sleep rand(3)
      value = queue.deq
      puts "General cunsumer got #{value}"
    }
  end

  types.each do |type|
    Thread.start do
      puts "#{type} consumer starts"
      loop {
        sleep rand(2)
        value = queue.deq(type)
        puts "#{type} cunsumer got #{value}"
      }
    end
  end

  sleep 10
end