
----------------------------------------------------------------
-- Hammerspoon 設定
----------------------------------------------------------------

-- キーコード
local eisuu = 0x66
local escape = 'escape'
local extendKey = 'F17'

-- グローバル
local normalizedKeyMap = {}

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

---------------------------------------------------------
-- キー入力監視
---------------------------------------------------------

-- 押下している独自修飾キー
local downedKeyMap = {}
-- 他のキーと組み合わせ済みの独自修飾キー（単独押し判定用）
local combinedKeyMap = {}

-- キーリマップリストの組み変え（アクセスし易いように）
-- {
--     "modKey": {
--         "single": "function(mods)",
--         "keys": {
--             "inKey": {"mods": ["outMods", ..], "key": "outKey", "func": "function(mods, events, self)"},
--             ..
--         }
--     },
--     ..
-- }
local function normalizeKeylist(list)
    local out = {}

    for _, val in pairs(list) do
        if out[val['mod']] == nil then out[val['mod']] = {} end
        local map = out[val['mod']]

        map['single'] = val['single']

        if map['keys'] == nil then map['keys'] = {} end
        for j, key in pairs(val['keys']) do
            map['keys'][key[1]] = {
                in_mods = key[2],
                mods = key[3],
                key =  key[4],
                func = key[5]
            }
        end
    end

    return out
end

-- キー入力ハンドラー
local keyHandler = function(ev)
    local keyCode = ev:getKeyCode()
    local eventType = ev:getType()
    local key = hs.keycodes.map[keyCode]

    -- キーダウン時
    if eventType == hs.eventtap.event.types.keyDown then
        --  独自修飾キーとの組み合わせ処理（独自修飾キーが押下済みで独自修飾キー以外のダウンイベント）
        for downedKey, v in pairs(downedKeyMap) do
            if downedKey ~= key and normalizedKeyMap[downedKey] ~= nil then
                if combinedKeyMap[downedKey] == nil then combinedKeyMap[downedKey] = {} end

                -- TODO: keyは押されているが、修飾キーとしての組み合わせが定義されていない場合
                -- 修飾キーが押されているかつ、in_modsとそれが完全に一致している場合

                -- 押されている修飾キーを取得
                -- local in_mods = {}
                -- for k, v in pairs(ev:getFlags()) do
                --     table.insert(in_mods, k)
                -- end
                -- modsの内容をhammerSpoonでプリントデバッグ

                -- if normalizedKeyMap[downedKey]['keys'][key] == nil thenのとき、alt+入力キーとする
                -- if normalizedKeyMap[downedKey]['keys'][key] == nil then
                --     local imods = {}
                --     for k, v in pairs(ev:getFlags()) do
                --         table.insert(imods, k)
                --     end
                --     table.insert(imods, "alt")
                --     local events = {}
                --     table.insert(events, hs.eventtap.event.newKeyEvent(imods, key, true))
                --     table.insert(combinedKeyMap[downedKey], {mods = imods, key = key})
                --     return true, events
                -- end
            
                if normalizedKeyMap[downedKey]['keys'][key] ~= nil then
                    local mods = {}
                    for k, v in pairs(ev:getFlags()) do
                        table.insert(mods, k)
                    end

                    -- 代替イベント（キーダウン）
                    local events = {}
                    local replacement = normalizedKeyMap[downedKey]['keys'][key]
                    if replacement['func'] ~= nil then replacement['func'](mods, events, replacement) end
                    if replacement['key'] ~= '' then
                        for i, mod in pairs(replacement['mods']) do table.insert(mods, mod) end
                        table.insert(events, hs.eventtap.event.newKeyEvent(mods, replacement['key'], true))
                    end

                    -- 組み合わせたキーと内容を保持しておく
                    combinedKeyMap[downedKey][key] = replacement
                    return true, events
                end
            end
        end

        -- 独自修飾キーの処理（独自修飾キーのダウンイベント）
        if normalizedKeyMap[key] ~= nil then
            if downedKeyMap[key] == nil then
                downedKeyMap[key] = true
            end
            -- キー自体のイベントは無効化（キーリピートも含まれるため）
            return true
        end

    -- キーアップ時
    elseif eventType == hs.eventtap.event.types.keyUp then
        -- 独自修飾キーの処理（独自修飾キーのアップイベント）
        if normalizedKeyMap[key] ~= nil then
            downedKeyMap[key] = nil

            -- 単体押し
            if combinedKeyMap[key] == nil then
                local mods = {}
                for k, v in pairs(ev:getFlags()) do
                    table.insert(mods, k)
                end
                -- 関数を呼ぶ
                if normalizedKeyMap[key]['single'] ~= nil then normalizedKeyMap[key]['single'](mods) end
                return true

            -- 組み合わせ済みの場合（独自修飾キーよりも先に組み合わせキーが離された場合）
            else
                -- 強制的に代替イベントのキーアップを呼ぶ
                local events = {}
                for k, val in pairs(combinedKeyMap[key]) do
                    table.insert(events, hs.eventtap.event.newKeyEvent(val['mods'], val['key'], false))
                end
                combinedKeyMap[key] = nil
                return true, events
            end
        end

        --  独自修飾キーとの組み合わせ処理（独自修飾キーが押下済みで独自修飾キー以外のアップイベント）
        for downedKey, v in pairs(downedKeyMap) do
            if downedKey ~= key and normalizedKeyMap[downedKey] ~= nil then
                if normalizedKeyMap[downedKey]['keys'][key] ~= nil then
                    -- 代替イベント（キーアップ）
                    local events = {}
                    local replacement = normalizedKeyMap[downedKey]['keys'][key]
                    if replacement['key'] ~= '' then
                        table.insert(events, hs.eventtap.event.newKeyEvent(replacement['mods'], replacement['key'], false))
                    end

                    -- 保持している処理を削除
                    if combinedKeyMap[downedKey] ~= nil then combinedKeyMap[downedKey][key] = nil end
                    return true, events
                end
            end
        end
    end
end

eventtap = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, keyHandler)
eventtap:start()

---------------------------------------------------------
-- キーカスタマイズ設定
---------------------------------------------------------
-- {
--     "mod": "modKey",
--     "single": "function(mods)",
--     "keys": [
--         ["inKey", ["outMods", ..], "outKey", "function(mods, events, self)"],
--         ..
--     ]
-- }
local extendKeyList = {
    {
        mod = extendKey,
        single = function(mods)
            hs.eventtap.event.newKeyEvent(eisuu, true):post()
            hs.eventtap.event.newKeyEvent(escape, true):post()
        end,
        keys = {
            -- IME切り替え
            -- ctrl + space だと意図通りに動かない…
            {'space', {}, {}, eisuu, function(mods, events, self)
                -- 自身の設定を組み替える
                    self['key'] = eisuu
            end},

            -- カーソル移動
            {'f', {}, {}, eisuu, function(mods, events, self)
                moveCursorToScreenPosition(2, 3/4) 

            end},
            {'d', {}, {}, eisuu, function(mods, events, self)
                moveCursorToScreenPosition(2, 1/4)  
            end},
            {'s', {}, {}, eisuu, function(mods, events, self)
                moveCursorToScreenPosition(1, 3/4)  
            end},
            {'a', {}, {}, eisuu, function(mods, events, self)
                moveCursorToScreenPosition(1, 1/4)  
            end},
            -- ファンクションキー
            {'delete', {}, {'ctrl'}, 'd'},
            {'w', {}, {'alt'}, 'tab'}
        }
    }
}

normalizedKeyMap = normalizeKeylist(extendKeyList)

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

