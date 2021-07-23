local awful = require("awful")
local LeftPanel = require("widgets.left-panel")
local TopPanel = require("widgets.top-panel")

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(
    function(s)
        if s.index == 1 then
            -- Create the leftPanel
            s.left_panel = LeftPanel(s)
            -- Create the Top bar
            s.top_panel = TopPanel(s, true)
        else
            -- Create the Top bar
            s.top_panel = TopPanel(s, false)
        end
    end
)

-- Hide bars when app go fullscreen
function updateBarsVisibility()
    for s in screen do
        if s.selected_tag then
            local fullscreen = s.selected_tag.fullscreenMode
            -- Order matter here for shadow
            s.top_panel.visible = not fullscreen
            if s.left_panel then
                s.left_panel.visible = not fullscreen
            end
        end
    end
end

_G.tag.connect_signal(
    "property::selected",
    function(s)
        updateBarsVisibility()
    end
)

_G.client.connect_signal(
    "property::fullscreen",
    function(c)
        c.first_tag.fullscreenMode = c.fullscreen
        updateBarsVisibility()
    end
)
