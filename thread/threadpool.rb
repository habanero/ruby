
require 'thread'

class ThreadPool

  #  === 引数
  #
  #  +max_size+::
  #    作成するスレッドの個数の上限
  #  +logger+::
  #  スレッドの作成やdead時にログを通知するオブジェクト <<メソッド必須
  def initialize(max_size, logger=nil)
    @max_size = max_size
    @queue = Queue.new
    @threads = []
    @create_thread_mutex = Mutex.new
    @logger = logger
  end

  #  === 引数
  #
  #  スレッドで実行させるコードブロック
  #
  #  === 詳細
  #  
  #  既に作成されたスレッドの個数が上限に満たない場合は新たにスレッドを作成する
  def execute(&block)
    @queue.push(block)
    @create_thread_mutex.synchronize do
      @threads << create_thread if @threads.size < @max_size
    end
  end

  #  === 詳細
  #  各スレッドの処理が完了するまでsleepする。
  #
  #  === 注意
  #
  #  untilが終わる条件が、 "queueでブロックされているスレッドの個数" == "スレッドの個数"　となっている。
  #  このため、あるワーカースレッドで例外が発生して、スレッドがdead状態になった場合、untilの条件は永久に満たされないので
  #  shutdownを実行したスレッドもデッドロックする。
  #  ワーカースレッド内で例外を必ず処理するか、shutdown_with_clean_upを使う。
  def shutdown
    until @queue.num_waiting == @threads.size
      sleep 0.01
    end
    kill
  end

  #  === 詳細
  #
  #  clean_upを呼びながらshutdownする
  def shutdown_with_clean_up
    until (@queue.num_waiting) == @threads.size
      sleep 0.01
      clean_up
    end
    kill
  end

  #  === 戻り値
  #
  #  例外で終了したワーカースレッドの個数
  #
  #  === 詳細
  #
  #  例外で終了したスレッドのstatusはnil
  #  http://www.ruby-lang.org/ja/man/html/Thread.html#status
  def dead_thread_count
    count = 0
    @threads.each{|t| count += 1 if t.status.nil? }
    count
  end

  private
  def create_thread
    t = Thread.start(@queue) do |q|
      loop{job = q.pop; job.call }
    end
    
    log("create thread:#{t.inspect}\n")
    t
  end

  def kill
    @threads.each {|t| t.kill; log("kill:#{t.inspect}\n") }
  end

  #  === 詳細
  #
  #  例外で終了したスレッドを削除して、新規にスレッドを作成する
  def clean_up
    @create_thread_mutex.synchronize do
      before = @threads.size
      @threads.reject!{ |t| t.status.nil? }
      reject_num = before - @threads.size

      if reject_num > 0
        log("thread dead count:#{reject_num}\n")
        reject_num.times{ @threads << create_thread }
      end
    end
  end

  def log(str)
    @logger << str if @logger
  end
end


if __FILE__ == $0
  t = ThreadPool.new(5, $stdout)
  100.times do |i|
    t.execute() {sleep 0.1}
  end
  t.shutdown
  puts "shutdown ended"

  t = ThreadPool.new(5, $stdout)
  100.times do |i|
    t.execute() {sleep 0.1}
  end
  t.shutdown_with_clean_up
  puts "shutdown_with_clean_up ended"

  t = ThreadPool.new(5, $stdout)
  100.times do |i|
    t.execute() {sleep 0.1; raise if i==1 or i==3 or i==10 or i==30}
  end
  t.shutdown_with_clean_up
  puts "shutdown_with_clean_up with raise ended"
end