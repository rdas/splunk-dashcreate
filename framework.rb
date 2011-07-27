require 'dsl.rb'
require 'optparse'

class View
    @@views = {}
    def initialize(visibleLabel, autoCancelInterval="90", isVisible=true, objectMode="SimpleDashboard", onunloadCancelJobs=true, refresh=-1, template="dashbaord.html")
        @label = visibleLabel
        @fileName = self.class.name
        @autoCancelInterval = autoCancelInterval
        @isVisible = isVisible
        @objectMode = objectMode
        @onunloadCancelJobs = onunloadCancelJobs
        @refresh = refresh
        @template = template
        @modules = []
    end

    attr_accessor :fileName

    def View.getInstanceByName(name)
        return @@views[name]    
    end

    def self.views
        return @@views
    end

    def addModule(mod)
        @modules.push(mod)
    end

    def evaluate()
        @str = "view "
        @str += ":autoCancelInterval => '#{@autoCancelInterval}', :isVisible => #{@isVisible}, :objectMode => '#{@objectMode}', :onunloadCancelJobs => #{@onunloadCancelJobs}, :refresh => #{@refresh}, :template => '#{@template}' do\n"
        @str += "  label {'#{@label}'}\n"
        
        @modules.each { |m| @str += m.evaluate() }

        @str += "end\n"
        return @str
    end
end

class MenuItem
    def initialize(label)
        @label = label
        @menuItems = []
        @holders = [] 
    end

    attr_accessor :label

    class Holder
        def initialize()
        end

        def evaluate()
            return ''
        end
    end

    class ViewHolder < Holder
        def initialize(view, isDefault)
            @view = view
            @isDefault = isDefault
        end
        def evaluate()
            str = "view :name => '#{@view.fileName}'"
            if @isDefault
                str += ", :default => true"
            end
            str += "\n" 
            return str
        end
    end

    class HrefHolder < Holder
        def initialize(url, display)
            @url = url
            @display = display
        end
        def evaluate()
            str = "a :href => '#{@url}' do\n"
            str += "'#{@display}'\n"
            str += "end\n"
            return str
        end
    end

    class DividerHolder < Holder
        def initialize()
        end
        def evaluate()
            return "divider\n"
        end
    end

    class SavedSearchHolder < Holder
        def initialize(name)
            @name = name
        end
        def evaluate()
            return "saved :name => '#{@name}'\n"
        end
    end

    class SavedSearchListHolder < Holder
        def initialize(match)
            @match = match
        end
        def evaluate()
            return "saved :source => 'all', :match => '#{@match}'\n"
        end
    end

    def addMenuItem(menuItem)
        @menuItems.push(menuItem)
    end 

    def addView(view, isDefault=false)
        @holders.push(ViewHolder.new(view, isDefault))
    end  

    def addSavedSearchList(match)
        @holders.push(SavedSearchListHolder.new(match))
    end

    def addSavedSearch(name)
        @holders.push(SavedSearchHolder.new(name))
    end

    def addHref(url, display)
        @holders.push(HrefHolder.new(url, display))
    end

    def addDivider()
        @holders.push(DividerHolder.new())
    end

    def evaluate()
        @str = "collection :label => '#{label}' do\n"
        @menuItems.each { |mitem| @str += mitem.evaluate() }
        @holders.each { |holder| @str += holder.evaluate() }
        @str += "end\n"

        return @str 
    end
end

class Navigation
    def initialize(menuItems={})
        @menuItems = menuItems
    end
    def addMenuItem(menuItem)
        @menuItems[menuItem.label] = menuItem           
    end
    def evaluate()
        @str = "nav do\n"
        @menuItems.each { |label, mi| @str += mi.evaluate() }
        @str += "end"
    end
end

class Property
    def initialize(key, value)
        @key = key
        @value = value
    end
    def evaluate()
        @str = "  param :name => '#{@key}' do\n"
        if @value.class.name == 'Property'
            @str += @value.evaluate()
        else 
            @str += "    '#{@value}'\n"
        end
        @str += "  end\n"
        return @str
    end
end

class Module
    def initialize(group=nil, moduleName=nil, layoutPanel=nil)
        @group= group
        @moduleName = moduleName
        @layoutPanel = layoutPanel
        @props = [] 
        @modules = []
    end
    def setProperty(name, value)
        @props.push(Property.new(name, value))
    end
    def setRowCol(row, col)
        @row = row
        @col = col
    end
    def addModule(mod)
        @modules.push(mod)
    end
    def evaluate()
        @str = "mod "
        if @moduleName
            @str += ":name => '#{@moduleName}'"
        end
        if @layoutPanel
            if @moduleName
                @str += ","
            end
            @str += " :layoutPanel => '#{@layoutPanel}'"
        end
        if @group
            if @moduleName or @layoutPanel
                @str += ","
            end
            @str += " :group=> '#{@group}'"
        end
        @str += " do\n"

        if @props.length > 0
            @props.each { |prop| @str += prop.evaluate() }
        end

        @modules.each { |m| @str += m.evaluate() }

        @str += "end\n"
        return @str
    end
end

class AccountBar < Module
    def initialize(layoutPanel='appHeader')
        super(nil, 'AccountBar', layoutPanel)
    end
end

class AppBar < Module
    def initialize(layoutPanel='navigationHeader')
        super(nil, 'AppBar', layoutPanel)
    end
end

class Message < Module
    def initialize(layoutPanel='messaging')
        super(nil, 'Message', layoutPanel)
    end
end

class TitleBar < Module
    def initialize(layoutPanel='viewHeader')
        super(nil, 'TitleBar', layoutPanel)
    end
end

class StaticContent < Module
    def initialize(layoutPanel, text)
        super(nil, 'StaticContentSample', layoutPanel)
        setProperty('text', text)
    end
end

class StandardView < View
    def initialize(label)
        super(label)

        addModule(AccountBar.new)
        addModule(AppBar.new)

        mess = Message.new
        mess.setProperty('filter', '*')
        mess.setProperty('clearOnJobDispatch', 'False')
        mess.setProperty('maxSize', '1')
        addModule(mess)

        mess1 = Message.new
        mess1.setProperty('filter', 'splunk.search.job')
        mess1.setProperty('clearOnJobDispatch', 'True')
        mess1.setProperty('maxSize', '1')
        addModule(mess1)

        titleBar = TitleBar.new
        titleBar.setProperty('actionsMenuFilter', 'dashboard')
        addModule(titleBar)
    end
end

class CommonModule < Module
    def initialize(layoutPanel, group, groupLabel, search, autoRun=true, isSavedSearch=false)
        if isSavedSearch
            super(group, 'HiddenSavedSearch', layoutPanel)
            setProperty('savedSearch', search)
        else
            super(group, 'HiddenSearch', layoutPanel)
            setProperty('search', search)
        end
        setProperty('groupLabel', groupLabel)


        hfp = Module.new(nil, 'HiddenFieldPicker', nil)
        hfp.setProperty('strictMode', 'True')

        if isSavedSearch
            vsa = Module.new(nil, 'ViewStateAdapter', nil)
            addModule(vsa)
            vsa.setProperty('savedSearch', search)
            vsa.addModule(hfp)
        else
            addModule(hfp)
        end

        jpi = Module.new(nil, 'JobProgressIndicator', nil)
        hfp.addModule(jpi)

        @jobProgressIndicator = jpi
    end

    def setEarliest(value)
        setProperty('earliest', value)
    end

    def setLatest(value)
        setProperty('latest', value)
    end
end

class Table < CommonModule
    def initialize(layoutPanel, group, groupLabel, search, properties=Nil, autoRun=true, isSavedSearch=false)
        super(layoutPanel, group, groupLabel, search, autoRun, isSavedSearch)

        ep = Module.new(nil, 'EnablePreview', nil)
        ep.setProperty('enable', 'True')
        ep.setProperty('display', 'False')
        
        srt = Module.new(nil, 'SimpleResultsTable', nil)
        if properties.nil?
            srt.setProperty('drilldown' 'row')
            srt.setProperty('allowTransformedFieldSelect', 'True')
        else 
            properties.each { |key, value| srt.setProperty(key, value) }
        end
       
        ctds = Module.new(nil, 'ConvertToDrilldownSearch', nil)

        vr = Module.new(nil, 'ViewRedirector', nil)
        vr.setProperty('viewTarget', 'flashtimeline')
        ctds.addModule(vr)
        srt.addModule(ctds)
        ep.addModule(srt)
    end
end

class SingleValue < CommonModule
    def initialize(layoutPanel, group, groupLabel, search, autoRun=true, isSavedSearch=false)
        super(layoutPanel, group, groupLabel, search, autoRun, isSavedSearch)

        sv = Module.new(nil, 'SingleValue', nil)
        sv.setProperty('classField', 'range')  

        @jobProgressIndicator.addModule(sv)
    end 
end

class RadialGauge < CommonModule
    def initialize(layoutPanel, group, groupLabel, search, autoRun=true, isSavedSearch=false)
        super(layoutPanel, group, groupLabel, search, autoRun, isSavedSearch)

        ep = Module.new(nil, 'EnablePreview', nil)
        ep.setProperty('enable', 'True')
        ep.setProperty('display', 'False')
        
        hcf = Module.new(nil, 'HiddenChartFormatter', nil)
        ep.addModule(hcf)

        fc = Module.new(nil, 'FlashChart', nil)
        fc.setProperty('width', '100%')
        hcf.addModule(fc)

        ctds = Module.new(nil, 'ConvertToDrilldownSearch', nil)
        fc.addModule(ctds)

        vr = Module.new(nil, 'ViewRedirector', nil)
        vr.setProperty('viewTarget', 'flashtimeline')
        ctds.addModule(vr)

        @jobProgressIndicator.addModule(ep)
    end
end

class Chart < CommonModule
    def initialize(layoutPanel, group, groupLabel, search, properties=Nil, autoRun=true, isSavedSearch=false)
        super(layoutPanel, group, groupLabel, search, autoRun, isSavedSearch)

        ep = Module.new(nil, 'EnablePreview', nil)
        ep.setProperty('enable', 'True')
        ep.setProperty('display', 'False')
        
        hcf = Module.new(nil, 'HiddenChartFormatter', nil)
        properties.each { |key, value| hcf.setProperty(key, value) }

        ep.addModule(hcf)

        fc = Module.new(nil, 'FlashChart', nil)
        fc.setProperty('width', '100%')
        hcf.addModule(fc)

        ctds = Module.new(nil, 'ConvertToDrilldownSearch', nil)
        fc.addModule(ctds)

        vr = Module.new(nil, 'ViewRedirector', nil)
        vr.setProperty('viewTarget', 'flashtimeline')
        ctds.addModule(vr)

        @jobProgressIndicator.addModule(ep)
    end
end

class LineChart < Chart
    def initialize(layoutPanel, group, groupLabel, search, properties=nil, autoRun=true, isSavedSearch=false)
        @myprops = {}
        @myprops['chart'] = 'line'
        if properties
            @myprops = @myprops.merge(properties)
        end
        super(layoutPanel, group, groupLabel, search, @myprops, autoRun, isSavedSearch)
    end
end

class BarChart < Chart
    def initialize(layoutPanel, group, groupLabel, search, properties=nil, autoRun=true, isSavedSearch=false)
        @myprops = {}
        @myprops['chart'] = 'bar'
        if properties
            @myprops = @myprops.merge(properties)
        end
        super(layoutPanel, group, groupLabel, search, @myprops, autoRun, isSavedSearch)
    end
end

class ColumnChart < Chart
    def initialize(layoutPanel, group, groupLabel, search, properties=nil, autoRun=true, isSavedSearch=false)
        @myprops = {}
        @myprops['chart'] = 'column'
        if properties
            @myprops = @myprops.merge(properties)
        end
        super(layoutPanel, group, groupLabel, search, @myprops, autoRun, isSavedSearch)
    end
end

class AreaChart < Chart
    def initialize(layoutPanel, group, groupLabel, search, properties=nil, autoRun=true, isSavedSearch=false)
        @myprops = {}
        @myprops['chart'] = 'area'
        if properties
            @myprops = @myprops.merge(properties)
        end
        super(layoutPanel, group, groupLabel, search, @myprops, autoRun, isSavedSearch)
    end
end

class PieChart < Chart
    def initialize(layoutPanel, group, groupLabel, search, properties=nil, autoRun=true, isSavedSearch=false)
        @myprops = {}
        @myprops['chart'] = 'pie'
        if properties
            @myprops = @myprops.merge(properties)
        end
        super(layoutPanel, group, groupLabel, search, @myprops, autoRun, isSavedSearch)
    end
end

class ScatterChart < Chart
    def initialize(layoutPanel, group, groupLabel, search, properties=nil, autoRun=true, isSavedSearch=false)
        @myprops = {}
        @myprops['chart'] = 'scatter'
        if properties
            @myprops = @myprops.merge(properties)
        end
        super(layoutPanel, group, groupLabel, search, @myprops, autoRun, isSavedSearch)
    end
end

