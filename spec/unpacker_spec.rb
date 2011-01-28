require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

# Preparing the file structure 
def clear!
  {'some_zip_files.zip' => 'zip_real', 'test_package.rar' => 'rar_real'}.each_pair do |taget|

    # Removes old files in the test directory
    Dir.glob(File.expand_path(File.dirname(__FILE__) + "/data/#{taget.last}/*")).each do |file|
      FileUtils.rm(file) if Mimer.identify(file).text?
    end

    src = File.expand_path(File.dirname(__FILE__) + "/data/o_files/#{taget.first}")
    dest = File.expand_path(File.dirname(__FILE__) + "/data/#{taget.last}/#{taget.first}")
    FileUtils.copy_file(src, dest)
  end

  # Removes old files in the test directory
  Dir.glob(File.expand_path(File.dirname(__FILE__) + "/data/movie_to/*")).each do |file|
    FileUtils.rm(file) if Mimer.identify(file).text?
  end
end

describe Unpack, "should work with the runner" do
  before(:each) do
    clear!
    @path = File.expand_path('spec/data/rar_real')
    @unpack = Unpack.runner!('spec/data/rar_real', remove: true, min_files: 0)
  end
  
  it "should unpack some files" do
    clear!   
    files = %x{cd #{@path} && ls}.split(/\n/).count
    Unpack.runner!('spec/data/rar_real', remove: true, min_files: 0)    
    %x{cd #{@path} && ls}.split(/\n/).count.should_not eq(files)
  end
  
  it "should have 1 directory" do
    @unpack.count.should eq(1)
  end
  
  it "should have 5 new files" do
    @unpack.first.should have(5).files
  end
  
  it "should only contain files that exists" do
    @unpack.first.files.each do |file|
      File.exists?(file).should be_true
    end
  end
  
  it "should only contain an existsing directory" do
    directory = @unpack.first.directory
    Dir.exists?(directory).should be_true
  end
  
  it "should not remove old files when the remove param isn't present" do
    clear!
    Unpack.runner!('spec/data/rar_real', min_files: 0)
    %x{cd #{@path} && ls}.should have(6).split(/\n/)
  end
  
  it "should remove old files if the remove param is present" do
    clear!
    Unpack.runner!('spec/data/rar_real', min_files: 0, remove: true)
    %x{cd #{@path} && ls}.should have(5).split(/\n/)
  end
  
  it "should not find any files if the {min_files} param is very large" do
    Unpack.runner!('spec/data/rar_real', min_files: 100).should be_empty
  end
end

describe Unpack do
  before(:each) do
    clear!
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
  before(:each) do
    clear!
  end
  
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
    clear!
    @path = File.expand_path('spec/data/zip_real')
    @unpack = Unpack.new(directory: @path, options: {min_files: 1})
    @unpack.prepare!
    @unpack.clean!
  end
  
  it "should find some zip files" do
    @unpack.should have_at_least(1).files
    @unpack.files.reject {|file| ! file.match(/\.zip$/) }.count.should > 0
  end
  
  it "should be able to unpack zip files" do
    @unpack.unpack!
    %x{cd #{@path} && ls}.split(/\n/).reject {|file| ! file.match(/\_real\_/)}.count.should > 0
  end
  
  it "should return a list of new files" do
    @unpack.should have(1).diff
  end
  
  it "should contain files" do
    @unpack.diff.first.should have(5).files
  end
  
  it "should have and directory" do
    @unpack.diff.first.directory.should_not be_nil
  end
  
  it "should only contain directories that is of the sort absolute" do
    @unpack.diff.first.directory.should match(/^\//)
  end
  
  it "should contain valid files and directories, even if we call it 5 times" do
    5.times do
      @unpack.diff.each do |work|
        work.files.each do |file|
          File.exists?(file).should be_true
        end
      end
    end
  end
end

describe Unpack, "should work on real files" do
  before(:each) do
    clear!
    @path = File.expand_path('spec/data/rar_real')
    @unpack = Unpack.new(directory: @path, options: {min_files: 0})
    @unpack.prepare!
    @unpack.clean!
    @unpack.unpack!
  end
  
  it "should the unpacked file when running the unpack! command" do
    %x{cd #{@path} && ls}.split(/\n/).reject {|file| ! file.match(/\_real\_/)}.count.should > 0
  end
  
  it "should be able to remove archive files after unpack" do
    files = %x{cd #{@path} && ls}.split(/\n/).count
    @unpack.wipe!
    %x{cd #{@path} && ls}.split(/\n/).count.should < files
  end
end

describe Unpack, "should work with all kind of paths" do
  it "should raise an exception if an invalid path is being used" do
    lambda{
      Unpack.new(directory: "/some/non/existing/dir")
    }.should raise_error(Exception)
  end
  
  it "should work with a relative path" do
    lambda{
      Unpack.new(directory: "spec")
    }.should_not raise_error(Exception)
  end
  
  it "should not work with an incorect relative path" do
    lambda{
      Unpack.new(directory: "spec/random")
    }.should raise_error(Exception)
  end
end