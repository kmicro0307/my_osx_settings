
--[[
    カーソル移動とウィンドウ切り替えを行うための関数
]]--

local function moveCursorToScreenPosition(screen_number, ratio)
    hs.mouse.setAbsolutePosition(getPositionBasedOnScreen(screen_number, ratio))
end

function getPositionBasedOnScreen(screen_number, ratio)
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)

    local rightScreen = screens[screen_number]

    if rightScreen then
        local frame = rightScreen:frame()
        local targetX = frame.x + frame.w * ratio
        local targetY = frame.y + frame.h / 2
        return {x = targetX, y = targetY}
    end
end

function getWindowsUnderPos(mousePoint)
    return hs.fnutils.filter(hs.window.orderedWindows(), function(win)
        local frame = win:frame()
        return mousePoint.x >= frame.x and mousePoint.x <= frame.x + frame.w
               and mousePoint.y >= frame.y and mousePoint.y <= frame.y + frame.h
    end)
end

-- function activateWindowUnderCursor()
--     local mousePoint = hs.mouse.getAbsolutePosition() 
--     local windowsUnderCursor = getWindowsUnderPos(mousePoint)[1]
--     if windowsUnderCursor then
--         windowsUnderCursor:focus() 
--     end
-- end

function activateWindowBasedOnScreenPos(screen_number, ratio)
    local pos = getPositionBasedOnScreen(screen_number, ratio)
    local windowsUnderCursor = getWindowsUnderPos(pos)[1]
    if windowsUnderCursor then
        windowsUnderCursor:focus() 
    end
end

function activateSecondWindowUnderCursor()
    local mousePoint = hs.mouse.getAbsolutePosition()
    local windowsUnderCursor = getWindowsUnderPos(mousePoint) 

    -- 二番目に前面にあるウィンドウを特定し、アクティブにする
    if #windowsUnderCursor >= 2 then
        local secondWindow = windowsUnderCursor[2]
        secondWindow:focus()
    end
end

-- アクティブなウィンドウの中心にカーソルを移動する関数
function moveCursorToCenterOfActiveWindow()
    local win = hs.window.focusedWindow() 
    if win then
        -- ウィンドウのフレーム（位置とサイズ）を取得
        local f = win:frame() 

        -- ウィンドウの中心点を計算
        local center = { x = f.x + f.w / 2, y = f.y + f.h / 2 }

        -- カーソルをウィンドウの中心に移動
        hs.mouse.setAbsolutePosition(center) 
    end
end


--[[
    アプリケーション起動のための関数 
]]--

local function remapApplicationKey(mods, key, appName)
    hs.hotkey.bind(mods, key, function()
        hs.application.launchOrFocus(appName)
        moveCursorToCenterOfActiveWindow()
    end, nil, nil)
end

--[[
    キーバインドの設定
]]--

-- 'left alt + a'
hs.hotkey.bind({"alt"}, "F13", function()
    activateSecondWindowUnderCursor()
end)

-- 'left alt +s'
hs.hotkey.bind({"alt"}, "F14", function()
    moveCursorToScreenPosition(2, 3/4)  
    activateWindowBasedOnScreenPos(2, 3/4)
end)

-- 'left alt +d'
hs.hotkey.bind({"alt"}, "F15", function()
    moveCursorToScreenPosition(1, 1/4)  
    activateWindowBasedOnScreenPos(1, 1/4)
end)

-- 'left alt + f'
hs.hotkey.bind({"alt"}, "F16", function()
    moveCursorToScreenPosition(1, 3/4) 
    activateWindowBasedOnScreenPos(1, 3/4)
end)

-- 'left alt + e'
hs.hotkey.bind({"alt"}, "F17", function()
    moveCursorToCenterOfActiveWindow()
end)

-- キーとアプリケーションの割り当て
remapApplicationKey({"cmd", "ctrl", "alt"}, "v", "/Applications/Visual Studio Code.app")
remapApplicationKey({"cmd", "ctrl", "alt"}, "c", "/Applications/Google Chrome.app")
remapApplicationKey({"cmd", "ctrl", "alt"}, "a", "/Applications/Arc.app")
remapApplicationKey({"cmd", "ctrl", "alt"}, "o", "/Applications/Obsidian.app")
remapApplicationKey({"cmd", "ctrl", "alt"}, "w", "/Applications/wezterm.app")
remapApplicationKey({"cmd", "ctrl", "alt"}, "i", "/Applications/IntelliJ IDEA.app")