require 'mimer_plus'

class Unpack
  attr_accessor :files
  
  def initialize(args)
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    
    @options = {
      :min_files => 5,
      :depth => 2,
      :absolute_path_to_unrar => "#{File.dirname(__FILE__)}/../bin/unrar"
    }
    
    @removeable = {}
    @options.merge!(args[:options]) if args[:options]
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
      if type.zip?
        self.unzip(path: File.dirname(file), file: file)
      elsif type.rar?
        self.unrar(path: File.dirname(file), file: file)
      else
        puts "Something went wrong, the mime type does not match zip or rar"
      end
    end
  end
  
  def unrar(args)
    %x(cd #{args[:path].gsub(/\s+/, '\ ')} && #{@options[:absolute_path_to_unrar]} e -y #{args[:file]})
    @removeable.merge!(args[:path] => 'rar')
  end

  def unzip(args)
    %x(unzip -n #{args[:file]} -d #{args[:path].gsub(/\s+/, '\ ')})
    @removeable.merge!(args[:path] => 'zip')
  end
  
  def find_file_type(file_type)
    %x{cd #{@directory} && find #{@directory} -type f -maxdepth #{(@options[:depth])} -name \"*.#{file_type}\"}.split(/\n/)
  end
  
  def wipe!
    @removeable.each do |value|
      path = value.first
      type = value.last
      
      # Finding every file in this directory
      Dir.glob(path + '/*').each do |file|
        # Is the found file as the same type as the one that got unpacked?
        FileUtils.rm(file) if Mimer.identify(file).send(:"#{type}?")
      end
    end
  end
end
