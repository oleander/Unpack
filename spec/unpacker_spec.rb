require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe Unpack do
  before(:each) do
    @unpack = Unpack.new(directory: File.expand_path('spec/data/rar'))
    @unpack.prepare!
  end
  
  it "should work" do
    @unpack.should be_instance_of(Unpack)
  end
  
  it "should list all rar files in a directory" do
    @unpack.should have_at_least(3).files
  end
  
  it "should only return rar-files" do
    @unpack.files.each {|file| file.should match(/\.rar$/)}
  end
  
  it "should contain a absolut path to the file" do
    @unpack.files.each {|file| file.should match(/^\//)}
  end
  
  it "should have some files with the name 'accessible'" do
    @unpack.files.reject {|file| ! file.match(/\_accessible\_/) }.count.should > 0
  end
  
  it "should only contain files that exists" do
    @unpack.files.each {|file| File.exists?(file).should be_true }
  end
  
  it "should not contain files that include a subtitle" do
    @unpack.clean!
    @unpack.files.each {|file| file.should_not match(/\_subtitle\_/) }
    @unpack.should have_at_least(2).files
  end
  
  it "should not find files to deep" do
    @unpack.clean!
    @unpack.files.each {|file| file.should_not match(/\_not\_/) }
  end
  
  it "should only contain one rar file for each directory" do
    @unpack.clean!
    @unpack.should have(3).files
  end
  
  it "should not contain any strange files" do
    @unpack.files.each {|file| file.should_not match(/\.strange$/)}
  end
end

describe Unpack, "should work with options" do
  it "should not return any files when min is set to 0" do
    @unpack = Unpack.new(directory: File.expand_path('spec/data/rar'), options: {depth: 0})
    @unpack.prepare!
    @unpack.should have(0).files
  end
  
  it "should return subtitles rar files when min files is set to o" do
    @unpack = Unpack.new(directory: File.expand_path('spec/data/rar'), options: {min_files: 0})
    @unpack.prepare!
    @unpack.clean!
    @unpack.files.reject {|file| ! file.match(/\_subtitle\_/) }.count.should > 0
  end
  
  it "should access some really deep files" do
    @unpack = Unpack.new(directory: File.expand_path('spec/data/rar'), options: {depth: 100})
    @unpack.prepare!
    @unpack.clean!
    @unpack.files.reject {|file| ! file.match(/\_not\_/) }.count.should > 0
  end
end

describe Unpack,"should work with zip files" do
  before(:all) do
    @unpack = Unpack.new(directory: File.expand_path('spec/data/zip'), options: {min_files: 1})
    @unpack.prepare!
    @unpack.clean!
  end
  
  it "should find some zip files" do
    @unpack.should have_at_least(1).files
    @unpack.files.each {|file| file.should match(/\.zip$/) }
  end
end

describe Unpack, "should work on real files" do
  before(:all) do
    @path = File.expand_path('spec/data/rar_real')
    @unpack = Unpack.new(directory: @path, options: {min_files: 0})
  end
  
  it "should the unpacked file when running the unpack! command" do
    @unpack.prepare!
    @unpack.clean!
    @unpack.unpack!
    
    %x{cd #{@path} && ls}.split(/\n/).reject {|file| ! file.match(/\_real\_/)}.count.should > 0
  end
end