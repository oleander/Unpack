class Container
  attr_accessor :files, :directory
  
  def initialize(args)
    args.keys.each { |name| instance_variable_set "@" + name.to_s, args[name] }
  end
  
  def files
    return @files if @called
    @files.map! {|file| "#{@directory}/#{file}"}
    @called = true
    @files
  end
end
  