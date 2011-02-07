require 'rspec'
require 'fileutils'
require 'digest/md5'

require "#{File.dirname(__FILE__)}/../lib/unpack"

RSpec.configure do |config|
  config.mock_with :rspec
end
