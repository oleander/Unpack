require 'mimer_plus'
require 'unpack/container'
require 'fileutils'

class Unpack
  attr_accessor :files, :options, :directory, :removeable
  
  def initialize(args)
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    
    @options = {
      :min_files              => 5,
      :depth                  => 2,
      :debugger               => false,
      :force_remove           => false,
      :remove                 => false,
      :to                     => false,
      :absolute_path_to_unrar => "#{File.dirname(__FILE__)}/../bin/unrar"
    }
    
    @removeable = {}
    
    @options.merge!(args[:options]) if args[:options]
    
    # If the path is relative
    @directory = File.expand_path(@directory) unless @directory.match(/^\//)
    
    # Makes shure that every directory structure looks the same
    @directory = Dir.new(@directory).path rescue nil
    
    raise Exception.new("You need to specify a valid path") if @directory.nil? or not system("test -r '#{@directory}'")
    raise Exception.new("You need unzip to keep going") if %x{whereis unzip}.empty?
    
    @files = []
  end
  
  def self.it!(args)
    # If no to argument is given, file will be unpacked in the same dir
    args[:to] = args[:to].nil? ? File.dirname(args[:file]) : args[:to]
    
    # Adding the options that is being passed to {it!} directly to {Unpack}
    this = self.new(:directory => args[:to], :options => {:min_files => 0, :to => true}.merge(args))
    
    # Is the file path absolute ? good, do nothing : get the absolute path
    file = args[:file].match(/^\//) ? args[:file] : File.expand_path(args[:file])
    
    this.files << file
    this.unpack!
    this.wipe! if this.options[:remove]
    
    # Only one files has been unpacked, that is why we select the first object in the list
    this.diff.first
  end
  
  def self.runner!(directory = '.', options = {})
    unpack = Unpack.new(:directory => directory, :options => options) rescue nil
    
    # If the initializer raised any excetions
    return [] if unpack.nil?
    unpack.prepare!
    unpack.clean!
    unpack.unpack!
    unpack.wipe! if options[:remove]
    unpack.diff
  end
  
  def prepare!
    @files = []
    
    ['zip', 'rar'].each do |type|
      @files << find_file_type(type)
    end
    
    @files.flatten!.map! {|file| File.expand_path(file, Dir.pwd)}
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
      
      # Have the user specified a destenation folder to where the files are going to be unpacked?
      # If so, use that, if not use the current location of the archive file
      path = self.options[:to] ? @directory : File.dirname(file)
      
      before = Dir.new(path).entries
      
      if type.zip?
        @removeable.merge!(path => {:file_type => 'zip'})
        self.unzip(:path => path, :file => file)
      elsif type.rar?
        @removeable.merge!(path => {:file_type => 'rar'})
        self.unrar(:path => path, :file => file)
      else
        puts "Something went wrong, the mime type does not match zip or rar" if @options[:debugger]
      end
      
      # What files/folders where unpacked?
      diff = Dir.new(path).entries - before
      
      @removeable[path] ? @removeable[path].merge!(:diff => diff) : @removeable.delete(path)
        
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
      
      # Does not remove anything if nothing where unpacked
      next if value.last[:diff].empty? and not @options[:force_remove]
      
      puts "Removing files in #{path}" if @options[:debugger]
      
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
    
    # Removing some non welcome data
    @removeable.reject! do |item,_|
      @removeable[item][:diff].nil? or @removeable[item][:diff].empty?
    end
    
    @removeable = @removeable.map do |value|
      Container.new(:files => value.last[:diff], :directory => value.first)
    end
    
    # Never return the hash
    @removeable.empty? ? [] : @removeable
  end
  
  def unrar(args)
    %x(cd '#{args[:path]}' && '#{@options[:absolute_path_to_unrar]}' e -y -o- '#{args[:file]}')
  end

  def unzip(args)
    %x(unzip -n '#{args[:file]}' -d '#{args[:path]}')    
  end
  
  def find_file_type(file_type)    
    %x{cd '#{@directory}' && find '#{@directory}' -type f -maxdepth '#{(@options[:depth])}' -name '*.#{file_type}'}.split(/\n/)
  end
end
