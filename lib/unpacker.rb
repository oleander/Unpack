class Unpack
  attr_accessor :files  
  def prepare(directory)
    @options = {
      :min => 5
    }
    
    directory.gsub!(/\s+/, '\ ')
    @files = %x{cd #{directory} && find #{directory} -type f -d 2 -name \"*.rar\"}.split(/\n/)
    @files.map! {|file| File.absolute_path(file)}
  end
  
  def clean!
    # Removing all folders that have less then {@options[:lim]} files in them
    # Those folders are offen subtitle folders 
    folders = @files.map {|file| File.dirname(file)}.uniq.reject {|folder| Dir.entries(folder).count <= (@options[:min] + 2)}
    @files.reject!{|file| not folders.include?(File.dirname(file))}    
    results = []
    
    # Finding one rar file for every folder
    @files.group_by{|file| File.dirname(file) }.each_pair{|_,file| results << file.sort.first }
    @files = results
  end
end
