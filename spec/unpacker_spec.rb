require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')
require "./#{File.dirname(__FILE__)}/../Unpack.rb"

describe Unpack do
  before(:each) do
    @unpack = Unpack.new()
    @unpack.prepare('/Users/linus/Documents/Projekt/UndertexterApp/Spec/Data/Rar/')
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
    @unpack.should have(2).files
  end
  
  it "should not contain any strange files" do
    @unpack.files.each {|file| file.should_not match(/\.strange$/)}
  end
  
  it "should be able to unpack" do
    
  end
end