local wibox = require("wibox")
local mat_list_item = require("widgets.mat-list-item")

return wibox.widget {
    wibox.widget {
        wibox.widget {
            text = "Hardware monitor",
            font = "FiraCode Nerd Font 12",
            widget = wibox.widget.textbox
        },
        widget = mat_list_item
    },
    require("widgets.left-panel.hardware-monitor.cpu-meter"),
    require("widgets.left-panel.hardware-monitor.ram-meter"),
    require("widgets.left-panel.hardware-monitor.temperature-meter"),
    require("widgets.left-panel.hardware-monitor.harddrive-meter"),
    layout = wibox.layout.fixed.vertical
}
