require 'mimer_plus'
require 'unpacker/container'
class Unpack
  attr_accessor :files, :options
  
  def initialize(args)
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    
    @options = {
      :min_files              => 5,
      :depth                  => 2,
      :debugger               => false,
      :absolute_path_to_unrar => "#{File.dirname(__FILE__)}/../bin/unrar"
    }
    
    @removeable = {}
    
    @options.merge!(args[:options]) if args[:options]
    
    # If the path is relative
    @directory = File.expand_path(@directory) unless @directory.match(/^\//)
    
    # Makes shure that every directory structure looks the same
    @directory = Dir.new(@directory).path rescue nil
    
    raise Exception.new("You need to specify a valid path") if @directory.nil? or not Dir.exist?(@directory)
    raise Exception.new("You need unzip to keep going") if %x{whereis unzip}.empty?
  end
  
  def self.runner!(directory = '.', options = {})
    unpack = Unpack.new(directory: directory, options: options) rescue nil
    
    # If the initializer raised any excetions
    return [] if unpack.nil?
    unpack.prepare!
    unpack.clean!
    unpack.unpack!
    unpack.wipe! if options[:remove]
    unpack.diff
  end
  
  def prepare!
    @directory.gsub!(/\s+/, '\ ')
    @files = []
    
    ['zip', 'rar'].each do |type|
      @files << find_file_type(type)
    end
    
    @files.flatten!.map! {|file| File.absolute_path(file)}
  end
  
  def clean!
    # Removing all folders that have less then {@options[:lim]} files in them
    # Those folders are offen subtitle folders 
    folders = @files.map {|file| File.dirname(file)}.uniq.reject {|folder| Dir.entries(folder).count <= (@options[:min_files] + 2)}
    @files.reject!{|file| not folders.include?(File.dirname(file))}    
    results = []
    
    # Finding one rar file for every folder
    @files.group_by{|file| File.dirname(file) }.each_pair{|_,file| results << file.sort.first }
    @files = results
  end
  
  def unpack!
    @files.each  do |file|
      type = Mimer.identify(file)
      path = File.dirname(file)
      before = Dir.new(path).entries

      if type.zip?
        @removeable.merge!(path => {:file_type => 'zip'})
        self.unzip(path: path, file: file)
      elsif type.rar?
        @removeable.merge!(path => {:file_type => 'rar'})
        self.unrar(path: path, file: file)
      else
        puts "Something went wrong, the mime type does not match zip or rar" if @options[:debugger]
      end
      
      # What files/folders where unpacked?
      diff = Dir.new(path).entries - before
      
      @removeable[path] and diff.any? ? @removeable[path].merge!(:diff => diff) : @removeable.delete(path)
        
      # Some debug info
      if @options[:debugger] and diff.any? and @removeable[path]
        puts "#{diff.count} where unpacked"
        puts "The archive was of type #{@removeable[path][:file_type]}"
        puts "The name of the file(s) are #{diff.join(', ')}"
        puts "The path is #{path}"
        STDOUT.flush
      end
    end
  end
  
  # Removes the old rar and zip files
  def wipe!
    @removeable.each do |value|
      path = value.first
      type = value.last[:file_type]
      
      # Finding every file in this directory
      Dir.glob(path + '/*').each do |file|
        # Is the found file as the same type as the one that got unpacked?
        FileUtils.rm(file) if Mimer.identify(file).send(:"#{type}?")
      end
    end
  end
  
  def diff
    # The code below this line can only be called once
    return @removeable if @removeable.first.class == Container
    @removeable = @removeable.map do |value|
      Container.new(files: value.last[:diff], directory: value.first)
    end
    
    # Never return the hash
    @removeable.empty? ? [] : @removeable
  end
  
  def unrar(args)
    %x(cd #{args[:path].gsub(/\s+/, '\ ')} && #{@options[:absolute_path_to_unrar]} e -y -o- #{args[:file]})
  end

  def unzip(args)
    %x(unzip -n #{args[:file]} -d #{args[:path].gsub(/\s+/, '\ ')})    
  end
  
  def find_file_type(file_type)    
    %x{cd #{@directory} && find #{@directory} -type f -maxdepth #{(@options[:depth])} -name \"*.#{file_type}\"}.split(/\n/)
  end
end
