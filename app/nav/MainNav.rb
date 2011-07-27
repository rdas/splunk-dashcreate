require 'framework.rb'

class MainNav < Navigation
    def initialize()
        super()

        menu0 = MenuItem.new('Inner')
        menu0.addDivider()

        menu1 = MenuItem.new('About')
        menu1.addView(View.getInstanceByName('EnvState'), true)
        menu1.addHref('mailto:se@splunk.com', 'Send Feedback...')
        menu1.addDivider()
        menu1.addSavedSearch("my saved search")
        menu1.addSavedSearchList('match')
        menu1.addMenuItem(menu0)

        addMenuItem(menu1)
    end
end
