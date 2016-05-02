require 'helper'

class TestKanokoApplicationConvert < Minitest::Test
  include Rack::Test::Methods

  class TestApp < Kanoko::Application::Convert
    class ResponseMock < Struct.new(:body, :content_type)
    end
    def http_get(uri)
      path = uri.to_s[7..-1] # 7 = 'http://'
      path.sub!(/\?.*/, '')
      ResponseMock.new(File.read("test/#{URI.decode_www_form_component(path)}"), "image/jpeg")
    end

    def after_response(res)
    end
  end

  def app
    TestApp.new
  end

  def setup
    Kanoko.configure.digest_func = "sha1"
    Kanoko.configure.secret_key = "test"
  end

  def assert_jpeg(expected, actual)
    expected_exif = EXIFR::JPEG.new(StringIO.new(expected))
    actual_exif = EXIFR::JPEG.new(StringIO.new(actual))
    assert_equal expected_exif.to_hash, actual_exif.to_hash
  end

  def assert_identify(command, actual, to: "")
    expected = Tempfile.create("expected") do |expected_file|
      system("convert -depth 8 #{command} test/src.jpg #{to}#{expected_file.path}")
      expected_file.read
    end
    assert expected == actual
  end

  def test_resize
    path = Kanoko.path_for(:resize, "10x10", "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert last_response.content_type == 'image/jpeg'
    assert_identify "-thumbnail 10x10 -define jpeg:size=10x10", last_response.body
  end

  def test_resize_and_crop
    path = Kanoko.path_for(:resize, "10x10", :crop, "5x5+1+1", "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert last_response.content_type == 'image/jpeg'
    assert_identify "-thumbnail 10x10 -define jpeg:size=10x10 -crop 5x5+1+1", last_response.body
  end

  def test_escaped_url
    function = [:resize, "10x10", :crop, "5x5+1+1"]
    src = "漢字.jpg"
    hash = Kanoko.make_hash(*function, src)
    path = "/#{hash}/#{function.map { |i| URI.encode_www_form_component(i) }.join('/')}/#{URI.encode_www_form_component(src)}"
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert last_response.content_type == 'image/jpeg'
    assert_identify "-thumbnail 10x10 -define jpeg:size=10x10 -crop 5x5+1+1", last_response.body
  end

  def test_auto_orient
    path = Kanoko.path_for(:auto_orient, "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert last_response.content_type == 'image/jpeg'
    assert_identify "-auto-orient", last_response.body
  end

  def test_resize_and_auto_orient
    path = Kanoko.path_for(:resize, "10x10", :auto_orient, "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert last_response.content_type == 'image/jpeg'
    assert_identify "-thumbnail 10x10 -define jpeg:size=10x10 -auto-orient", last_response.body
  end

  def test_to_another_ext
    path = Kanoko.path_for(:to, 'png', :strip, "src.jpg")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert last_response.content_type == 'image/png'
    assert_identify "-strip -background none", last_response.body, to: "png:"
  end

  def test_with_query
    path = Kanoko.path_for(:resize, "12x13", "src.jpg?v=123")
    get path
    assert last_response.ok?
    assert 0 < last_response.body.length
    assert last_response.content_type == 'image/jpeg'
  end

  def test_undefined_func
    path = Kanoko.path_for(:undefined, "10x10", "src.jpg")
    get path
    assert_equal 400, last_response.status
    assert_equal "", last_response.body
  end

  def test_root_not_found
    path = "/"
    get path
    assert_equal 404, last_response.status
    assert_equal "", last_response.body
  end

  def test_invalid_path
    path = "/invalid/path/to/src"
    get path
    assert_equal 400, last_response.status
    assert_equal "", last_response.body
  end

  class Kanoko::Application::Convert::Function
    def method_for_500
      ['-undefined-imagemagick-option']
    end
  end

  def test_500
    path = Kanoko.path_for(:method_for_500, "src.jpg")
    out, err = capture_subprocess_io do
      get path
    end
    assert_equal 500, last_response.status
    assert_equal "", last_response.body
    assert_match /convert: unrecognized option `-undefined-imagemagick-option'/, err
  end
end
