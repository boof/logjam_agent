require_relative "test_helper.rb"
require_relative "sinatra_app"
require "rack/test"

module LogjamAgent
  class SinatraTest < MiniTest::Test
    def setup
      @@receiver ||= LogjamAgent::Receiver.new
      LogjamAgent.enable!
    end

    def teardown
      LogjamAgent.disable!
    end

    def logjam_message
      @@receiver.receive
    end

    include ::Rack::Test::Methods

    def app
      SinatraTestApp
    end

    def test_root
      get '/index?mumu=1&password=5'
      assert_equal 'Hello World!', last_response.body
      assert_equal 200, last_response.status

      stream, topic, payload = logjam_message
      assert_equal "myapp-test", stream
      assert_equal "logs.myapp.test", topic
      assert_equal 200, payload["code"]
      assert_equal "Simple#index", payload["action"]
      assert_kind_of Float, payload["total_time"]
      assert_kind_of String, payload["started_at"]
      assert_kind_of Integer, payload["started_ms"]
      assert_kind_of String, payload["ip"]
      # assert_kind_of Float, payload["view_time"]
      lines = payload["lines"]
      assert_match(/Started GET.*password=\[FILTERED\]/, lines[0][2])
      assert_match(/Hello World/, lines[1][2])
      assert_match(/Completed 200 OK/, lines[2][2])
      assert_nil(lines[3])
      request_info = payload["request_info"]
      method, url, query_parameters = request_info.values_at(*%w(method url query_parameters))
      assert_equal method, "GET"
      assert_equal url, "/index?mumu=1&password=[FILTERED]"
      assert_equal(query_parameters, { "mumu" => "1", "password" => "[FILTERED]" })
    end

  end
end
