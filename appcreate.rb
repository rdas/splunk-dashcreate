require 'framework.rb'

class ArgumentParser < Hash
    def initialize(args)
        super()
        self[:inputpath] = ''
        self[:outputpath] = ''

        opts = OptionParser.new do |opts|
            opts.banner = "Usage: #$0 [options]"
            opts.on('-o', '--output_path [STRING]', 'root path for generated xml output') do |string|
                self[:outputpath] = string || '$'
            end

            opts.on('-i', '--input_path STRING', 'root path for dsl input') do |string|
                self[:inputpath] = string || '$'
            end

            opts.on('-h', '--help', 'display this help and exit') do
                puts opts
                exit
            end
        end

        opts.parse!(args)
    end
end

def evaluateFiles(inbase, inpath, outpath)
    Dir.glob(File.join(inpath, '**', '*.rb')).each do |file| 

        x = XML::XMLBuilder.new

        require file
        className = File.basename(file, '.rb')
        instance = Object.const_get(className).new
        
        #save the instance in a global so we can refer to it when
        #building the nav 
        View.views[className] = instance

        x.dashboard do
            #puts instance.evaluate()
            if outpath
                writepath = file.sub(inbase, outpath).sub('.rb', '.xml')
                puts "Creating => #{writepath}"
                File.open(writepath, 'w') {|f| f.write(eval(instance.evaluate())) }
            else
                puts "********************* processing => #{file}"
                puts eval(instance.evaluate())
            end
        end
    end
end


arguments = ArgumentParser.new(ARGV)
if arguments[:outputpath] != ''
    output_path = arguments[:outputpath]
else
    output_path = nil
end

input_path = arguments[:inputpath]


#Evaluate all views first
evaluateFiles("#{input_path}", "#{input_path}/views", output_path)

#Evaluate navigation
evaluateFiles("#{input_path}", "#{input_path}/nav", output_path)
