p = SingleValue.new('panel_row1_col1',
                            'End-to-End Average Transaction Duration',
                            'Average Transaction Performance',
                            '* | head 1 | eval count = "493 ms" | rangemap field=count default=severe'))
addOrCreatePanel(p, "IT Operations", "Operational Visibility")
