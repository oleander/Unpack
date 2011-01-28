class Unpack
  attr_accessor :files
  
  def initialize(args)
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
    
    @options = {
      :min_files => 5,
      :depth => 2
    }
    
    @options.merge!(args[:options]) if args[:options]
  end
   
  def prepare!
    @directory.gsub!(/\s+/, '\ ')
    @files = %x{cd #{@directory} && find #{@directory} -type f -maxdepth #{(@options[:depth])} -name \"*.rar\"}.split(/\n/)
    @files.map! {|file| File.absolute_path(file)}
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
    @files.each do |file|
      self.unrar(file)
    end
  end
  
  def unrar(full_path_to_file)
    path = File.dirname(full_path_to_file)
    %x(cd #{path.gsub(/\s+/, '\ ')} && unrar e -y #{full_path_to_file})
  end

  # def unzip(path, filename)
  #    %x(unzip -n /tmp/#{filename} -d #{path.gsub(/\s+/, '\ ')})
  # end
end
