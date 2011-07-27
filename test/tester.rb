require 'dsl'

include XML

def cdata
    puts 'blah'
end

numbers = [1, 2, 3, 4]

xml_str = xml.project :name => 'ActiveObjects' do
    entity :id => 2
    entity :id => 4, :value => 'nothing-"ish"' do
        'content'
    end
    xmlentity :name => 'meh'
    
    numbers.each do |n|
        number { n }
    end
    
    target :name => 'all' do
        meta do
            'This is some inner text <with> illegal & chars'
        end
        test_elem :id => 3
        meta do
            cdata 'This is some more inner text with its > own "bad chars'
        end
        test_elem :id => 4, :eval => false
    end
    element :test, :value => 'test text' do
        sub_element
    end
    
    entity :id => 3
end

puts xml_str
