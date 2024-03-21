-- カーソルを特定の画面の特定の位置に移動させる関数
local function moveCursorToScreenPosition(screen_number, ratio)
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)

    local rightScreen = screens[screen_number]

    if rightScreen then
        local frame = rightScreen:frame()
        local targetX = frame.x + frame.w * ratio
        local targetY = frame.y + frame.h / 2
        hs.mouse.setAbsolutePosition({x = targetX, y = targetY})
    end
end

function activateWindowUnderCursor()
    local mousePoint = hs.mouse.getAbsolutePosition() -- マウスの絶対座標を取得
    local windowUnderMouse = hs.fnutils.find(hs.window.orderedWindows(), function(win)
        local frame = win:frame()
        return mousePoint.x >= frame.x and mousePoint.x <= frame.x + frame.w
               and mousePoint.y >= frame.y and mousePoint.y <= frame.y + frame.h
    end)

    if windowUnderMouse then
        windowUnderMouse:focus() 
    end
end

function activateSecondWindowUnderCursor()
    local mousePoint = hs.mouse.getAbsolutePosition() -- マウスの絶対座標を取得
    local allWindows = hs.window.orderedWindows() -- 表示順にソートされたウィンドウのリストを取得

    -- カーソルの下にあるウィンドウをフィルタリング
    local windowsUnderCursor = hs.fnutils.filter(allWindows, function(win)
        local frame = win:frame()
        return mousePoint.x >= frame.x and mousePoint.x <= frame.x + frame.w
               and mousePoint.y >= frame.y and mousePoint.y <= frame.y + frame.h
    end)

    -- 二番目に前面にあるウィンドウを特定し、アクティブにする
    if #windowsUnderCursor >= 2 then
        local secondWindow = windowsUnderCursor[2]
        secondWindow:focus()
    end
end

-- アクティブなウィンドウの中心にカーソルを移動する関数
function moveCursorToCenterOfActiveWindow()
    local win = hs.window.focusedWindow() -- アクティブなウィンドウを取得
    if win then
        local f = win:frame() -- ウィンドウのフレーム（位置とサイズ）を取得
        local center = { x = f.x + f.w / 2, y = f.y + f.h / 2 } -- ウィンドウの中心点を計算
        hs.mouse.setAbsolutePosition(center) -- カーソルをウィンドウの中心に移動
    end
end


-- キーボードショートカットでカーソルの下にある二番目に前にあるウィンドウをアクティブにする
hs.hotkey.bind({"alt"}, "F13", function()
    activateSecondWindowUnderCursor()
end)

-- カーソル移動 + カーソルの下にあるウィンドウをアクティブにする
hs.hotkey.bind({"alt"}, "F14", function()
    moveCursorToScreenPosition(1, 3/4)  
    activateWindowUnderCursor()
end)

hs.hotkey.bind({"alt"}, "F15", function()
    moveCursorToScreenPosition(2, 1/4)  
    activateWindowUnderCursor()
end)

hs.hotkey.bind({"alt"}, "F16", function()
    moveCursorToScreenPosition(2, 3/4) 
    activateWindowUnderCursor()
end)

-- 'alt + e'が押されたときに実行
hs.hotkey.bind({"alt"}, "F17", function()
    moveCursorToCenterOfActiveWindow()
end)


-- 指定したアプリケーションを開き、カーソルを中心に移動する汎用関数
function onKeyPressed(appName)
    -- プリントデバッグ
    hs.application.launchOrFocus(appName)
    moveCursorToCenterOfActiveWindow()
end

-- 特定のキーにアプリケーション起動のアクションを割り当てる関数
local function remapApplicationKey(key, appName)
    hs.hotkey.bind({"cmd", "ctrl", "alt"}, key, function()
        onKeyPressed(appName)
    end, nil, nil)
end

-- セミコロンキーのイベントをバインド
-- hs.hotkey.bind("", "f18", onSemicolonPressed, nil, nil)
-- キーとアプリケーションの割り当て
remapApplicationKey("v", "/Applications/Visual Studio Code.app")
remapApplicationKey("c", "/Applications/Google Chrome.app")
remapApplicationKey("o", "/Applications/Obsidian.app")
remapApplicationKey("w", "/Applications/wezterm.app")
remapApplicationKey("i", "/Applications/IntelliJ IDEA.app")

