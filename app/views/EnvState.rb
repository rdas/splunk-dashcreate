require 'framework.rb'

class EnvState < StandardView
    def initialize()
        super('Environment State')
        addModule(SingleValue.new('panel_row1_col1',
                                    'End-to-End Average Transaction Duration',
                                    'Average Transaction Performance',
                                    '* | head 1 | eval count = "493 ms" | rangemap field=count default=severe'))

        addModule(StaticContent.new('panel_row2_col1',
                                      'Average web server transaction duration in ms over the last 5 minutes'))

        addModule(RadialGauge.new('panel_row2_col1',
                                    'Web Servers',
                                    'Web Servers',
                                    'AppMgmt - Web Server - Radial Gauge'))

        addModule(StaticContent.new('panel_row2_col1',
                                      'Average application server transaction duration in ms over the last 5 minutes'))

        addModule(RadialGauge.new('panel_row2_col2',
                                    'App Servers',
                                    'App Servers',
                                    'AppMgmt - App Server - Radial Gauge'))

        addModule(LineChart.new('panel_row3_col1',
                                  'MyLineChart',
                                  'MyLineChart',
                                  'this is my in-line search',
                                  nil,
                                  true))

        addModule(LineChart.new('panel_row3_col1',
                                  'MyLineChart',
                                  'MyLineChart',
                                  'this is my in-line search',
                                  nil,
                                  true))
    end
end
