# -*- encoding: utf-8 -*-

require 'rake'
require 'date'

Gem::Specification.new do |s|
  s.name = 'sub_object'.sub(/.*/){|c| (c == File.basename(Dir.pwd)) ? c : raise("ERROR: s.name=(#{c}) in gemspec seems wrong!")}
  s.version = "1.0.1".sub(/.*/){|c| fs = Dir.glob('changelog{,.*}', File::FNM_CASEFOLD); raise('More than one ChangeLog exist!') if fs.size > 1; warn("WARNING: Version(s.version=#{c}) already exists in #{fs[0]} - ok?") if fs.size == 1 && !IO.readlines(fs[0]).grep(/^\(Version: #{Regexp.quote c}\)$/).empty? ; c }  # n.b., In macOS, changelog and ChangeLog are identical in default.
  # s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  # s.bindir = 'bin'
  # %w(sub_object).each do |f|
  #   path = s.bindir+'/'+f
  #   File.executable?(path) ? s.executables << f : raise("ERROR: Executable (#{path}) is not executable!")
  # end
  s.authors = ["Masa Sakano"]
  s.date = %q{2019-11-07}.sub(/.*/){|c| (Date.parse(c) == Date.today) ? c : raise("ERROR: s.date=(#{c}) is not today!")}
  s.summary = %q{Parent class for memory-efficient sub-Something}
  s.description = %q{Class SubObject that is the parent class for Ruby SubString and SubArray classes and alike, providing the base interface. This and child classes use negligible memory space, as their instance holds the positional information only.  It behaves exactly like the source object (duck-typing), except destructive modification is prohibited.  If the original source object is destructively altered, the corresponding instance can detect it and issue warning.}
  # s.email = %q{abc@example.com}
  s.extra_rdoc_files = [
     #"LICENSE.txt",
     "README.en.rdoc",
  ]
  s.license = 'MIT'
  s.files = FileList['.gitignore','lib/**/*.rb','[A-Z]*','test/**/*.rb', '*.gemspec'].to_a.delete_if{ |f|
    ret = false
    arignore = IO.readlines('.gitignore')
    arignore.map{|i| i.chomp}.each do |suffix|
      if File.fnmatch(suffix, File.basename(f))
        ret = true
        break
      end
    end
    ret
  }
  s.files.reject! { |fn| File.symlink? fn }

  # s.add_runtime_dependency 'rails'
  # s.add_development_dependency "bourne", [">= 0"]
  s.homepage = %q{https://www.wisebabel.com}
  s.rdoc_options = ["--charset=UTF-8"]

  # s.require_paths = ["lib"]	# Default "lib"
  s.required_ruby_version = '>= 2.0'  # respond_to_missing?
  s.test_files = Dir['test/**/*.rb']
  s.test_files.reject! { |fn| File.symlink? fn }
  # s.requirements << 'libmagick, v6.0' # Simply, info to users.
  # s.rubygems_version = %q{1.3.5}      # This is always set automatically!!

  ## cf. https://guides.rubygems.org/specification-reference/#metadata
  s.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.
  s.metadata["changelog_uri"]     = "https://github.com/masasakano/#{s.name}/blob/master/ChangeLog"
  # s.metadata["source_code_uri"]   = "https://github.com/masasakano/sub_object"
  # s.metadata["documentation_uri"] = "https://www.example.info/gems/bestgemever/0.0.1"
end

end

