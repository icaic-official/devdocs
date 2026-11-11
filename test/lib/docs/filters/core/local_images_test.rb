require_relative '../../../../test_helper'
require_relative '../../../../../lib/docs'
require 'chunky_png'
require 'tmpdir'

class LocalImagesFilterTest < Minitest::Spec
  include FilterTestHelper
  self.filter_class = Docs::LocalImagesFilter

  before do
    Docs::LocalImagesFilter.cache.clear
    @source_directory = Dir.mktmpdir
    context[:source_directory] = @source_directory
    FileUtils.mkpath(File.join(@source_directory, '_images'))
  end

  after do
    FileUtils.rm_rf(@source_directory)
  end

  # Random pixels, which neither PNG nor WebP can compress below the size limits
  def write_png(path, size)
    random = Random.new(1)
    image = ChunkyPNG::Image.new(size, size)
    size.times { |x| size.times { |y| image[x, y] = ChunkyPNG::Color.rgb(random.rand(256), random.rand(256), random.rand(256)) } }
    File.binwrite(File.join(@source_directory, path), image.to_blob)
  end

  it "embeds an image of the source directory" do
    write_png('_images/plot.png', 8)
    @body = '<img src="http://localhost/_images/plot.png">'
    assert_match %r{\Adata:image/(png|webp);base64,}, filter_output.at_css('img')['src']
  end

  it "removes an image that isn't in the source directory" do
    @body = '<img src="http://localhost/_images/missing.png">'
    assert_nil filter_output.at_css('img')
  end

  it "leaves images that aren't local alone" do
    @body = '<img src="https://example.com/plot.png">'
    assert_equal 'https://example.com/plot.png', filter_output.at_css('img')['src']
  end

  it "removes an image over the default size limit when the scraper sets none" do
    write_png('_images/big.png', 400)
    @body = '<img src="http://localhost/_images/big.png">'
    assert_nil filter_output.at_css('img')
  end

  it "keeps an image under the scraper's size limit" do
    write_png('_images/big.png', 400)
    context[:max_image_size] = 10_000_000
    @body = '<img src="http://localhost/_images/big.png">'
    assert filter_output.at_css('img')['src'].start_with?('data:image/')
  end
end
