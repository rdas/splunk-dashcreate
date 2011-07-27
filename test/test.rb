require 'dsl.rb'
xml.dashboard do
view :autoCancelInterval => '90', :isVisibl3 => true, :objectMode => 'SimpleDashboard', :onunloadCancelJobs => true, :refresh => -1, :template => 'dashbaord.html' do
  label {'Environment State'}
mod :name => 'AccountBar', :layoutPanel => 'appHeader' do
end
mod :name => 'AppBar', :layoutPanel => 'navigationHeader' do
end
mod :name => 'Message', :layoutPanel => 'messaging' do
  param :name => 'clearOnJobDispatch' do
    'False'
  end
  param :name => 'filter' do
    'splunk.search.job'
  end
  param :name => 'maxSize' do
    1
  end
end
end
    
end

puts xml
