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
    path = Kanoko.path_for(:resize, "10x10", "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert_jpeg File.read("test/resize.jpg"), last_response.body
  end

  def test_resize_and_crop
    path = Kanoko.path_for(:resize, "10x10", :crop, "5x5+1+1", "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert_jpeg File.read("test/resize_and_crop.jpg"), last_response.body
  end

  def test_auto_orient
    path = Kanoko.path_for(:auto_orient, "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert_jpeg File.read("test/src.jpg"), last_response.body
  end

  def test_resize_and_auto_orient
    path = Kanoko.path_for(:resize, "10x10", :auto_orient, "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert_jpeg File.read("test/resize.jpg"), last_response.body
  end

  def test_undefined_func
    path = Kanoko.path_for(:undefined, "10x10", "src.jpg")
    get path
    assert_equal 400, last_response.status
  end

  def test_root_not_found
    path = "/"
    get path
    assert_equal 404, last_response.status
  end

  def test_invalid_path
    path = "/invalid/path/to/src"
    get path
    assert_equal 400, last_response.status
  end
end
