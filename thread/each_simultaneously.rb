
module Enumerable

  #  === 詳細
  #  each_with_indexのmap版
  def map_with_index
    result = []
    each_with_index{|e, i| result << yield(e, i)}
    result
  end

  #  === 引数
  #
  #  同時実行させるコードブロック
  #
  #  === 戻り値
  #
  #  スレッドの配列
  #
  #  === 詳細
  #  eachの各要素ごとにスレッドを作成して、与えられたコードブロックを実行する
  def each_simultaneously
    threads = []
    each{|e| threads << Thread.start{ yield e} }
    threads
  end

  #  === 引数
  #
  #  同時実行させるコードブロック
  #
  #  === 戻り値
  #
  #  コードブロックの戻り値を格納した配列
  #
  #  === 詳細
  #  eachの各要素ごとにスレッドを作成して、与えられたコードブロックを実行する
  #  全てのスレッドにjoinして、コードブロックを評価した配列を得る
  def each_simultaneously_join
    result = []
    map_with_index{|e, i| Thread.start{ result[i] = yield e} }.each{|t| t.join}
    result
  end
end

if __FILE__ == $0
  block = Proc.new do |i|
    sleep i
    puts i
  end

  ary = [3, 2, 1]
  ary.each(&block)
  threads = ary.each_simultaneously(&block)
  threads.each{|t| t.join}

  p ary.each_simultaneously_join{|e| e*2}
end
