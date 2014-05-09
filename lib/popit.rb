require 'json'

require 'httparty'

# A Ruby wrapper for the PopIt API.
#
# Instead of writing the path to an API endpoint, you can use method chaining.
# For example:
#
#     require 'popit'
#     api = PopIt.new :instance_name => 'demo'
#     api.get 'persons/john-doe'
#
# can be written as:
#
#     api.persons('john-doe').get
#
# All methods and arguments between `api` and the HTTP method - in this case,
# `get` - become parts of the path.
#
# @see https://github.com/mysociety/popit/blob/master/lib/apps/api/api_v1.js
class PopIt
  class Error < StandardError; end
  class PageNotFound < Error; end
  class ServiceUnavailable < Error; end
  class NotAuthenticated < Error; end

  include HTTParty

  # The instance name.
  attr_reader :instance_name
  # The PopIt API's host name, eg "popit.mysociety.org".
  attr_reader :host_name
  # The PopIt API's port, eg 80
  attr_reader :port
  # The PopIt API version, eg "v0.1"
  attr_reader :version
  # A user name.
  attr_reader :username
  # The user's password.
  attr_reader :password
  # The maximum number of retries in case of HTTP 503 Service Unavailable errors.
  attr_reader :max_retries

  # Initializes a PopIt API client.
  #
  # @param [Hash] opts the API client's configuration
  # @option opts [String] :instance_name the instance name
  # @option opts [String] :host_name the PopIt API's host name, eg "popit.mysociety.org"
  # @option opts [String] :post the PopIt API's port, eg 80
  # @option opts [String] :version the PopIt API version, eg "v1"
  # @option opts [String] :user a user name
  # @option opts [String] :password the user's password
  # @option opts [String] :max_retries the maximum number of retries in case of
  #  HTTP 503 Service Unavailable errors
  def initialize(opts = {})
    unless opts.has_key?(:instance_name)
      raise ArgumentError, 'Missing key :instance_name'
    end

    @instance_name = opts[:instance_name]
    @host_name     = opts[:host_name]   || 'popit.mysociety.org'
    @port          = opts[:port]        || 80
    @version       = opts[:version]     || 'v0.1'
    @username      = opts[:user]
    @password      = opts[:password]
    @max_retries   = opts[:max_retries] || 0

  end

  # Sends a GET request.
  #
  # @param [String] path a path with no leading slash
  # @param [Hash] opts key-value pairs for the query string
  # @return the JSON response from the server
  def get(path, opts = {})
    request(:get, path, opts)
  end

  # Sends a POST request.
  #
  # @param [String] path a path with no leading slash
  # @param [Hash] opts key-value pairs for the message body
  # @return the JSON response from the server
  def post(path, opts = {})
    request(:post, path, opts)
  end

  # Sends a PUT request.
  #
  # @param [String] path a path with no leading slash
  # @param [Hash] opts key-value pairs for the message body
  # @return [nil] nothing
  def put(path, opts = {})
    request(:put, path, opts)
  end

  # Sends a DELETE request.
  #
  # @param [String] path a path with no leading slash
  # @param [Hash] opts key-value pairs for the query string
  # @return [Hash] an empty hash
  def delete(path, opts = {})
    request(:delete, path, opts)
  end

private

  def request(http_method, path, opts = {})
    attempts ||= 0

    path = "http://#{instance_name}.#{host_name}:#{port}/api/#{version}/#{path}"

    response = case http_method
    when :get
      self.class.send(http_method, path, :query => opts)
    when :delete
      self.class.send(http_method, path, :basic_auth => {:username => username, :password => password}, :query => opts)
    when :post, :put
      self.class.send(http_method, path, :basic_auth => {:username => username, :password => password}, :body => JSON.dump(opts), :headers => {'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    end

    unless ['200', '201', '204'].include?(response.response.code)
      message = if Hash === response.parsed_response
        if response.parsed_response['error']
          response.parsed_response['error']
        elsif response.parsed_response['errors']
          response.parsed_response['errors'].join(', ')
        else
          response.parsed_response
        end
      else
        response.parsed_response
      end

      case response.response.code
      when '503'
        raise PopIt::ServiceUnavailable, message
      when '404'
        raise PopIt::PageNotFound, message
      when '401'
        raise PopIt::NotAuthenticated, message
      else
        raise PopIt::Error, message
      end
    end

    response.parsed_response && response.parsed_response['result']
  rescue PopIt::ServiceUnavailable
    attempts += 1
    if attempts <= max_retries
      sleep attempts ** 2
      retry
    else
      raise
    end
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
      @klass.get(chain.join('/'), opts)
    end

    def post(opts = {})
      @klass.post(chain.join('/'), opts)
    end

    def put(opts = {})
      @klass.put(chain.join('/'), opts)
    end

    def delete(opts = {})
      @klass.delete(chain.join('/'), opts)
    end

    def method_missing(*args)
      @chain += args
      self
    end
  end
end
