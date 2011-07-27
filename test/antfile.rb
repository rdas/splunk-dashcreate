require 'dsl.rb'

xml.tab_increment = '    '

xml.project :name => 'ActiveObjects', :default => :build do
    dirname :property => 'activeobjects.dir', :file => '${ant.file.ActiveObjects}'
    property :file => '${activeobjects.dir}/build.properties'
    
    target :name => :init do
        mkdir :dir => '${activeobjects.dir}/bin'
    end
    
    target :name => :build, :depends => :init do
        javac :srcdir => '${activeobjects.dir}/src', :source => 1.5, :debug => true
    end
    
    target :name => :check_test do
        property :name => 'test-check-ok', :value => true
    end
    
    target :name => :build_test, :depends => [:check_test, :init, :build], :if => 'test-check-ok' do
        property :name => 'javadoc.intern.path', :value => '${activeobjects.dir}/${javadoc.path}'
    end
end

puts xml
