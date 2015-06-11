require 'digest/sha1'
require 'minitest/autorun'
require "rack/test"
require "kanoko/application/convert"

class TestKanokoApplicationConvert < Minitest::Test
  include Rack::Test::Methods

  class TestApp < Kanoko::Application::Convert
    class ResponseMock < Struct.new(:body)
    end
    def http_get(uri)
      ResponseMock.new(File.read "test/src.jpg")
    end
    def after_response(res)
    end
  end

  def app
    TestApp.new
  end

  def assert_digest(expected, actual)
    assert_equal Digest::SHA1.hexdigest(expected), Digest::SHA1.hexdigest(actual)
  end

  def setup
    ENV['RACK_ENV'] = 'test'
    Kanoko.configure.digest_func = "sha1"
    Kanoko.configure.secret_key = "test"
  end

  def test_resize
    url = Kanoko.path_for(:resize, "10x10", "src.jpg")
    get url, {}, {"REQUEST_URI" => url}
    assert_digest File.read("test/resize.jpg"), last_response.body
  end

  def test_resize_and_crop
    url = Kanoko.path_for(:resize, "10x10", :crop, "5x5+1+1", "src.jpg")
    get url, {}, {"REQUEST_URI" => url}
    assert_digest File.read("test/resize_and_crop.jpg"), last_response.body
  end

  def test_not_found
    get "/nothing"
    assert_equal 404, last_response.status

    post "/nothing"
    assert_equal 404, last_response.status

    delete "/nothing"
    assert_equal 404, last_response.status
  end
end
