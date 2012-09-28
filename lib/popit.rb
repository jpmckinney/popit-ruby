require 'httparty'
require 'yajl'

# A Ruby wrapper for the PopIt API.
#
# Instead of writing the path to an API endpoint, you can use method chaining.
# For example:
#
#     require 'popit'
#     api = PopIt.new :instance_name => 'demo'
#     api.get 'person/john-doe'
#
# can be written as:
#
#     api.person('john-doe').get
#
# All methods and arguments between `api` and the HTTP method - in this case,
# `get` - become parts of the path.
#
# @see https://github.com/mysociety/popit/blob/master/lib/apps/api/api_v1.js
class PopIt
  class Error < StandardError; end

  include HTTParty

  # The instance name.
  attr_reader :instance_name
  # The PopIt API's host name, eg "popit.mysociety.org".
  attr_reader :host_name
  # The PopIt API's port, eg 80
  attr_reader :port
  # The PopIt API version, eg "v1"
  attr_reader :version
  # A user name.
  attr_reader :username
  # The user's password.
  attr_reader :password

  # Initializes a PopIt API client.
  #
  # @param [Hash] opts the API client's configuration
  # @option opts [String] :instance_name the instance name
  # @option opts [String] :host_name the PopIt API's host name, eg "popit.mysociety.org"
  # @option opts [String] :post the PopIt API's port, eg 80
  # @option opts [String] :version the PopIt API version, eg "v1"
  # @option opts [String] :user a user name
  # @option opts [String] :password the user's password
  def initialize(opts = {})
    unless opts.has_key? :instance_name
      raise ArgumentError, 'Missing key :instance_name'
    end

    @instance_name = opts[:instance_name]
    @host_name     = opts[:host_name] || 'popit.mysociety.org'
    @port          = opts[:port]
    @version       = opts[:version]   || 'v1'
    @username      = opts[:user]
    @password      = opts[:password]
  end

  # Sends a GET request.
  #
  # @param [String] path a path with no leading slash
  # @param [Hash] opts key-value pairs for the query string
  # @return the JSON response from the server
  def get(path, opts = {})
    request :get, path, opts
  end

  # Sends a POST request.
  #
  # @param [String] path a path with no leading slash
  # @param [Hash] opts key-value pairs for the message body
  # @return the JSON response from the server
  def post(path, opts = {})
    request :post, path, opts
  end

  # Sends a PUT request.
  #
  # @param [String] path a path with no leading slash
  # @param [Hash] opts key-value pairs for the message body
  # @return [nil] nothing
  def put(path, opts = {})
    request :put, path, opts
  end

  # Sends a DELETE request.
  #
  # @param [String] path a path with no leading slash
  # @param [Hash] opts key-value pairs for the query string
  # @return [Hash] an empty hash
  def delete(path, opts = {})
    request :delete, path, opts
  end

private

  def request(http_method, path, opts = {})
    path = "http://#{instance_name}.#{host_name}:#{port}/api/#{version}/#{path}"

    response = case http_method
    when :get
      self.class.send http_method, path, :query => opts
    when :delete
      self.class.send http_method, path, :basic_auth => {:username => username, :password => password}, :query => opts
    when :post, :put
      self.class.send http_method, path, :basic_auth => {:username => username, :password => password}, :body => opts
    end

    unless ['200', '201', '204'].include? response.response.code
      message = if response.response.content_type == 'text/html'
        response.response.code
      else
        response.response.body
      end
      raise PopIt::Error, message
    end

    response.parsed_response
  end

  def method_missing(*args)
    Chain.new(self, args)
  end

  class Chain
    attr_reader :klass, :chain

    def initialize(klass, chain)
      @klass = klass
      @chain = chain
    end

    def get(opts = {})
      @klass.get chain.join('/'), opts
    end

    def post(opts = {})
      @klass.post chain.join('/'), opts
    end

    def put(opts = {})
      @klass.put chain.join('/'), opts
    end

    def delete(opts = {})
      @klass.delete chain.join('/'), opts
    end

    def method_missing(*args)
      @chain += args
      self
    end
  end
end
