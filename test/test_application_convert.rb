require 'digest/sha1'
require 'stringio'
require 'minitest/autorun'
require "rack/test"
require "exifr"
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

  def setup
    ENV['RACK_ENV'] = 'test'
    Kanoko.configure.digest_func = "sha1"
    Kanoko.configure.secret_key = "test"
  end

  def assert_jpeg(expected, actual)
    expected_exif = EXIFR::JPEG.new(StringIO.new(expected))
    actual_exif = EXIFR::JPEG.new(StringIO.new(actual))
    assert_equal expected_exif.to_hash, actual_exif.to_hash
  end

  def test_resize
    url = Kanoko.path_for(:resize, "10x10", "src.jpg")
    get url, {}, {"REQUEST_URI" => url}
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert_jpeg File.read("test/resize.jpg"), last_response.body
  end

  def test_resize_and_crop
    url = Kanoko.path_for(:resize, "10x10", :crop, "5x5+1+1", "src.jpg")
    get url, {}, {"REQUEST_URI" => url}
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert_jpeg File.read("test/resize_and_crop.jpg"), last_response.body
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
