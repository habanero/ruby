# リファクタリングRubyに書いてあったコードを少し修正

require 'net/http'
require 'uri'

class Gateway
  attr_accessor :subject, :attributes, :to, :authenticate
  def initialize
    @subject = nil
    @attributes = []
    @to = ""
    @authenticate = {}
  end

  def self.execute
    gateway = self.new
    yield gateway
    gateway.execute
  end

  def build_request
    raise 'abstruct method called Gateway#bild_request'
  end

  def execute
    request = build_request
    request.basic_auth(@authenticate[:user], @authenticate[:pass]) unless @authenticate.empty?
    Net::HTTP.new(url.host, url.port).start{|http| http.request(request) }
  end

  def url
    URI.parse(to)
  end
end

class PostGateway < Gateway
  def build_request
    request = Net::HTTP::Post.new(url.path)
    attribute_hash = attributes.inject({}) do |result, attribute|
      result[attribute.to_s] = subject.__send__ attribute
      result
    end
    request.set_form_data(attribute_hash)
    request
  end
end

class GetGateway < Gateway
  def build_request
    params = attributes.map do |attribute|
      "#{attribute}=#{subject.__send__(attribute)}"
    end.join("&")
    Net::HTTP::Get.new("#{url.path}?#{params}")
  end
end

class GatewayExpressionBuilder
  def initialize(subject)
    @subject = subject
    @attributes = []
    @authenticate = {}
    @gateway = nil
  end

  def post(*attributes)
    @attributes = attributes
    @gateway = PostGateway
    self
  end

  def get(*attributes)
    @attributes = attributes
    @gateway = GetGateway
    self
  end

  def with_authentication(conf)
    @authenticate = conf
    self
  end

  def to(address)
    @gateway.execute do |persist|
      persist.subject = @subject
      persist.attributes = @attributes
      persist.authenticate = @authenticate
      persist.to = address
    end
  end
end

module HTTPDomainObject
  def http
    GatewayExpressionBuilder.new(self)
  end
end

if __FILE__ == $0
  class Google
    include HTTPDomainObject
    def get
      http.get.to('http://www.google.co.jp/')
    end
  end

  p Google.new.get #=> #<Net::HTTPOK 200 OK readbody=true>

  class Hatena
    include HTTPDomainObject
    attr_accessor :word
    def post
      http.post(:word).to('http://search.hatena.ne.jp/questsearch')
    end
  end

  h = Hatena.new
  h.word = "ruby" 
  p h.post #=> #<Net::HTTPOK 200 OK readbody=true>
end
