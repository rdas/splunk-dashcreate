nav = Navigation.new()

menu0 = MenuItem.new('Inner')
menu0.addDivider()

menu1 = MenuItem.new('About')
menu1.addView(v, true)
menu1.addHref('mailto:se@splunk.com', 'Send Feedback...')
menu1.addDivider()
menu1.addSavedSearch("my saved search")
menu1.addSavedSearchList('match')
menu1.addMenuItem(menu0)

nav.addMenuItem(menu1)
