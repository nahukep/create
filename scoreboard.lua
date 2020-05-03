script_name('ImGui Scoreboard')
script_description('ImGui SA:MP Scoreboard')
script_dependencies('SAMPFUNCS', 'Dear ImGui')
script_moonloader(025)

require 'moonloader'
require 'SAMPFUNCS'
local imgui = require 'imgui'
local notf
if doesFileExist(getWorkingDirectory() .. "\\imgui_notf.lua") then
	notf = import 'imgui_notf.lua'
end
local vkeys = require 'vkeys'
local bitex = require 'bitex'
local SE = require 'lib.samp.events'
local memory = require 'memory'
local encoding = require 'encoding'
local inicfg = require 'inicfg'
u8 = encoding.UTF8
encoding.default = 'CP1251'

local russian_characters = {
	[168] = '�', [184] = '�', [192] = '�', [193] = '�', [194] = '�', [195] = '�', [196] = '�', [197] = '�', [198] = '�', [199] = '�', [200] = '�', [201] = '�', [202] = '�', [203] = '�', [204] = '�', [205] = '�', [206] = '�', [207] = '�', [208] = '�', [209] = '�', [210] = '�', [211] = '�', [212] = '�', [213] = '�', [214] = '�', [215] = '�', [216] = '�', [217] = '�', [218] = '�', [219] = '�', [220] = '�', [221] = '�', [222] = '�', [223] = '�', [224] = '�', [225] = '�', [226] = '�', [227] = '�', [228] = '�', [229] = '�', [230] = '�', [231] = '�', [232] = '�', [233] = '�', [234] = '�', [235] = '�', [236] = '�', [237] = '�', [238] = '�', [239] = '�', [240] = '�', [241] = '�', [242] = '�', [243] = '�', [244] = '�', [245] = '�', [246] = '�', [247] = '�', [248] = '�', [249] = '�', [250] = '�', [251] = '�', [252] = '�', [253] = '�', [254] = '�', [255] = '�',
}
local quitReason = {
  "������� / ����",
  "����� �� ����",
  "������ / �������"
}
local themsDir = getWorkingDirectory() .. "\\resource\\scoreboard"
local allset = inicfg.load({
	set = {
		curTheme = "main",
		type = 1,
		titlebar = 0,
		streamcheck = false,
		npcshow = false,
		fontSize = 2,
		nickType = 0,
		list = 0
	},
	cheat = {
		clog = false
	}
}, "scoreboard")
local groups = inicfg.load({
	friend = {},
	admin = {},
	enemy = {}
}, "playergroupscoreboard")
if allset.set.fontSize < 0 or allset.set.fontSize > 4 then
	allset.set.fontSize = 2
end
local cfg = nil
local copColor = {
	[12] = {11},
	[6] = {29},
	[3] = {5, 19},
	[8] = {15},
	[23] = {16},
	[24] = {17},
	[25] = {18}
}
local setTable = {
	["���� ����� / ������"] = {
		[8] = "��� ��������",
		[9] = "��� ���������",
		[10] = "��� �������"
	},
	["������"] = {
		[26] = "��� ��������",
		[27] = "��� ���������",
		[28] = "��� �������"
	},
	["����"] = {
		[12] = "���������",
		[3] = "��� ����",
		[6] = "�����������",
		[1] = "�����"
	},
	["������"] = {
		[23] = "��� ��������",
		[24] = "��� ���������",
		[25] = "��� �������"
	}
}
local sizesFont = {"12", "13", "14", "15", "16"}
local sFont = {}
local style = imgui.GetStyle()
local colors = style.Colors
local clr = imgui.Col
local ImVec4 = imgui.ImVec4
local background = nil
local bgImage = imgui.ImBool(false)

function loadTheme(name)
	cfg = inicfg.load({
		colors = {
			[1] = imgui.ImColor(240, 240, 240, 240):GetU32(),
			[3] = imgui.ImColor(3, 3, 0, 230):GetU32(),
			[8] = imgui.ImColor(210, 210, 0, 100):GetU32(),
			[6] = imgui.ImColor(110, 110, 127, 127):GetU32(),
			[9] = imgui.ImColor(210, 210, 0, 140):GetU32(),
			[10] = imgui.ImColor(210, 210, 0, 70):GetU32(),
			[12] = imgui.ImColor(120, 120, 0, 232):GetU32(),
			[23] = imgui.ImColor(180, 180, 0, 163):GetU32(),
			[24] = imgui.ImColor(180, 180, 0, 100):GetU32(),
			[25] = imgui.ImColor(180, 180, 0, 100):GetU32(),
			[26] = imgui.ImColor(160, 160, 160, 60):GetU32(),
			[27] = imgui.ImColor(160, 160, 160, 60):GetU32(),
			[28] = imgui.ImColor(160, 160, 160, 30):GetU32()
		},
		set = {
			bgimg = false,
			imageColor = imgui.ImColor(255, 255, 255, 255):GetU32()
		}
	}, name and (themsDir .. "\\" .. name .. "\\data.ini") or ("moonloader\\resource\\scoreboard\\main\\data.ini"))
	bgImage.v = cfg.set.bgimg
	for k, v in pairs(cfg.colors) do
		colors[k] = imgui.ImColor(v):GetVec4()
	end
	for k, v in pairs(copColor) do
		for _, iv in ipairs(copColor[k]) do
			colors[iv] = colors[k]
		end
	end
	if doesFileExist(name and (themsDir .. "\\" .. name .. "\\scoreboard.png") or ("moonloader\\resource\\scoreboard\\main\\scoreboard.png")) then
		background = imgui.CreateTextureFromFile(name and (themsDir .. "\\" .. name .. "\\scoreboard.png") or ("moonloader\\resource\\scoreboard\\main\\scoreboard.png"))
	else
		background = nil
	end
end

local ToScreen = convertGameScreenCoordsToWindowScreenCoords
local show_main_window = imgui.ImBool(false)
local show_set_window = imgui.ImBool(false)
local searchBuf = imgui.ImBuffer(256)
local createThemBuf = imgui.ImBuffer(32)
local playerCount = 0
local streamCheck = imgui.ImBool(allset.set.streamcheck)
local cStyle = imgui.ImInt(0)
local cType = imgui.ImInt(allset.set.type)
local bTitlebar = imgui.ImInt(allset.set.titlebar)
local cSize = imgui.ImInt(allset.set.fontSize)
local cNType = imgui.ImInt(allset.set.nickType)
local bNpcShow = imgui.ImBool(allset.set.npcshow)
local bConnectLog = imgui.ImBool(allset.cheat.clog)
local logConFilter = imgui.ImBuffer(128)
local ScrollToButton = false
local logConnect = {}
local thems = {}
local themsId = {}
local notThems = false
local focusId = -1
local scrollToId = false
local gameInit = false
local pMarker = {}
local bMarkPlayer = imgui.ImBool(false)
local mColor = {}
local cFilter = imgui.ImInt(allset.set.list)
local cSetGroup = imgui.ImInt(0)
loadTheme(allset.set.curTheme)
bgImage.v = cfg.set.bgimg
if not doesDirectoryExist("moonloader\\resource") then
	createDirectory("moonloader\\resource")
end
if not doesDirectoryExist("moonloader\\resource\\scoreboard") then
	createDirectory("moonloader\\resource\\scoreboard")
end
do
function apply_custom_style()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	style.WindowRounding = 1.5
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ChildWindowRounding = 1.5
	style.FrameRounding = 1.0
	style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
	style.ScrollbarSize = 13.0
	style.ScrollbarRounding = 0
	style.GrabMinSize = 8.0
	style.GrabRounding = 1.0
	-- style.Alpha =
	style.WindowPadding = imgui.ImVec2(0.0, 0.0)
	-- style.WindowMinSize =
	style.FramePadding = imgui.ImVec2(2.5, 3.5)
	-- style.ItemInnerSpacing =
	-- style.TouchExtraPadding =
	-- style.IndentSpacing =
	-- style.ColumnsMinSpacing = ?
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	-- style.DisplayWindowPadding =
	-- style.DisplaySafeAreaPadding =
	-- style.AntiAliasedLines =
	-- style.AntiAliasedShapes =
	-- style.CurveTessellationTol =
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	-- colors[clr.PopupBg]                = ImVec4(0.04, 0.04, 0.04, 0.9)
	-- print(clr.ScrollbarGrab)
	-- print(clr.Header)
	colors[clr.ComboBg]                = colors[clr.PopupBg]
	-- colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.05, 0.05, 0.05, 0.79)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	-- colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	-- colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	-- colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	-- colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CheckMark]              = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.28, 0.28, 0.28, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.35, 0.35, 0.35, 1.00)
	-- colors[clr.Header]                 = ImVec4(0.12, 0.12, 0.12, 0.94)
	-- colors[clr.HeaderHovered]          = ImVec4(0.25, 0.25, 0.25, 0.2)
	-- colors[clr.HeaderActive]           = ImVec4(0.16, 0.16, 0.16, 0.90)
	-- colors[clr.Separator]              = colors[clr.Border]
	colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
	colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.10, 0.10, 0.10, 0.35)
	-- colors[clr.WindowBg]               = imgui.ImColor(3, 3, 0, 230):GetVec4()
	-- colors[clr.FrameBg]    	 		  = imgui.ImColor(210, 210, 0, 100):GetVec4()
	-- colors[clr.FrameBgHovered]         = imgui.ImColor(210, 210, 0, 140):GetVec4()
	-- colors[clr.FrameBgActive]          = imgui.ImColor(210, 210, 0, 70):GetVec4()
	-- colors[clr.TitleBg]                = imgui.ImColor(120, 120, 0, 232):GetVec4()
	-- colors[clr.TitleBgActive]          = imgui.ImColor(120, 120, 0, 232):GetVec4()
	-- colors[clr.Button]                 = imgui.ImColor(180, 180, 0, 163):GetVec4()
	-- colors[clr.ButtonHovered]          = imgui.ImColor(180, 180, 0, 100):GetVec4()
	-- colors[clr.ButtonActive]           = imgui.ImColor(100, 100, 0, 100):GetVec4()
end
apply_custom_style()
end
function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(0) end

	local h, n = findFirstFile('moonloader\\resource\\scoreboard\\*')
	local i = 1
	while true do
		wait(0)
		if h then
			if n then
				if doesDirectoryExist("moonloader\\resource\\scoreboard\\" .. n) and n ~= "." and n ~= ".." then
					table.insert(thems, n)
					themsId[tostring(n)] = i
					if allset.set.curTheme == n then
						cStyle.v = i - 1
					end
					i = i + 1
				end
				n = findNextFile(h)
			else
				findClose(h)
				if #thems == 0 then
					thems[1] = "main"
					themsId["main"] = 1
					notThems = true
					loadTheme()
				end
			end
		end
		imgui.Process = show_main_window.v
		if wasKeyPressed(VK_TAB) and not isPauseMenuActive() then
			if not show_main_window.v then
				if not sampIsChatInputActive() then
					toggleScoreboard(true)
				end
			else
				toggleScoreboard(false)
			end
		end
		for k, v in pairs(pMarker) do
			local result, ped = sampGetCharHandleBySampPlayerId(k)
			if result then
				local color = sampGetPlayerColor(k)
				if doesBlipExist(pMarker[k]) then
					if mColor[v] ~= color then
						removeBlip(v)
						pMarker[k] = addBlipForChar(ped)
						mColor[pMarker[k]] = color
						changeBlipColour(pMarker[k], alpha255(color))
						changeBlipDisplay(pMarker[k], 3)
						setBlipAlwaysDisplayOnZoomedRadar(pMarker[k], true)
					end
				else
					pMarker[k] = addBlipForChar(ped)
					mColor[pMarker[k]] = color
					changeBlipColour(pMarker[k], alpha255(color))
					changeBlipDisplay(pMarker[k], 3)
					setBlipAlwaysDisplayOnZoomedRadar(pMarker[k], true)
				end
			end
		end
	end
end

function toggleScoreboard(flag)
	if type(flag) == 'boolean' then
		show_main_window.v = flag
	else
		show_main_window.v = not show_main_window.v
	end
	if show_main_window.v then
		if focusId > -1 then
			scrollToId = true
		end
		if bConnectLog.v then
			ScrollToButton = true
		end
	end
end

function getLocalPlayerId()
	local _, id = sampGetPlayerIdByCharHandle(playerPed)
	return id
end

function onWindowMessage(msg, wparam, lparam)
	if(msg == 0x100 or msg == 0x101) then
		if wparam == VK_TAB then
			consumeWindowMessage(true, false)
		end
		if(wparam == VK_ESCAPE and show_main_window.v) and not isPauseMenuActive() then
			consumeWindowMessage(true, false)
			if(msg == 0x101)then
				toggleScoreboard(false)
			end
		end
	end
end


local glyph_ranges = nil
function imgui.BeforeDrawFrame()
    if not fontChanged then
        fontChanged = true
        glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
        imgui.GetIO().Fonts:Clear()
        imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arialbd.ttf', 14, nil, glyph_ranges)
				for _, v in ipairs(sizesFont) do
					sFont[tonumber(v)] = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arialbd.ttf', tonumber(v), nil, glyph_ranges)
				end
				imgui.RebuildFonts()
    end
end
function imgui.OnDrawFrame()
	-- notf.onRenderNotification()
	if show_main_window.v then
		if show_set_window.v then
			local x, y = ToScreen(510, 30)
			local w, h = ToScreen(638, 175)
			imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(4.0, 4.0))
			imgui.SetNextWindowPos(imgui.ImVec2(w-220, y), imgui.Cond.FirstUseEver, imgui.ImVec2(0.0, 0.0))
			imgui.SetNextWindowSize(imgui.ImVec2(220, 270), imgui.Cond.FirstUseEver)
			imgui.Begin(u8'���������', show_set_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize)
			imgui.Separator()
			imgui.AlignTextToFramePadding()
			imgui.Text(u8"����:")
			imgui.SameLine()
			imgui.PushItemWidth(113)
			local rThems = {}
			for k, v in ipairs(thems) do
				rThems[k] = u8(v)
			end
			if imgui.Combo("##thems", cStyle, rThems) and #thems > 0 then
				if notThems then
					inicfg.save(cfg, "..\\resource\\scoreboard\\main\\data.ini")
					notThems = false
				else
					inicfg.save(cfg, "..\\resource\\scoreboard\\" .. allset.set.curTheme .. "\\data.ini")
				end
				allset.set.curTheme = thems[cStyle.v + 1]
				inicfg.save(allset, "scoreboard")
				loadTheme(allset.set.curTheme)
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			if imgui.Button(u8"�������") then
				imgui.OpenPopup(u8"������� ����")
			end
			if imgui.BeginPopupModal(u8"������� ����", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
				imgui.Text(u8"������� �������:")
				imgui.InputText("##createThemBuf", createThemBuf, imgui.InputTextFlags.CharsNoBlank)
				if imgui.Button(u8"����������", imgui.ImVec2(100, 0)) then
					imgui.CloseCurrentPopup()
					if createThemBuf.v:len() > 0 and themsId[tostring(u8:decode(createThemBuf.v))] == nil then
						createDirectory(themsDir .. "\\" .. u8:decode(createThemBuf.v))
						themsId[tostring(u8:decode(createThemBuf.v))] = #themsId
						thems[#thems+1] = u8:decode(createThemBuf.v)
					end
				end
				imgui.SameLine()
				if imgui.Button(u8"�������", imgui.ImVec2(100, 0)) then
					imgui.CloseCurrentPopup()
				end
				imgui.EndPopup()
			end
			imgui.Separator()
			if imgui.CollapsingHeader(u8"����� ���������") then
				imgui.AlignTextToFramePadding()
				imgui.Text(u8"������ ����:")
				imgui.SameLine()
				imgui.PushItemWidth(127)
				if imgui.Combo("##type", cType, {u8"���������", u8"�������", u8"�������", u8"�� ���� �����"}) and #thems > 0 then
					allset.set.type = cType.v
				end
				imgui.Separator()
				imgui.AlignTextToFramePadding()
				imgui.Text(u8"���������:")
				imgui.SameLine()
				imgui.PushItemWidth(139)
				if imgui.Combo("##header", bTitlebar, {u8"��������", u8"������ �����", u8"������"}) then
					allset.set.titlebar = bTitlebar.v
				end
				imgui.Separator()
				imgui.AlignTextToFramePadding()
				imgui.Text(u8"������ ������:")
				imgui.SameLine()
				imgui.PushItemWidth(116)
				if imgui.Combo("##size", cSize, sizesFont) then
					allset.set.fontSize = cSize.v
				end
				imgui.Separator()
				imgui.AlignTextToFramePadding()
				imgui.Text(u8"���� �������:")
				imgui.SameLine()
				imgui.PushItemWidth(120)
				if imgui.Combo("##ntype", cNType, {u8"��������", u8"���� ��������", u8"��� �����"}) then
					allset.set.nickType = cNType.v
				end
			end
			imgui.Separator()
			if imgui.CollapsingHeader(u8"�����������") then
				if imgui.Checkbox(u8"���������� �����������", bgImage) then
					cfg.set.bgimg = bgImage.v
				end
				local color = imgui.ImFloat4(imgui.ImColor(cfg.set.imageColor):GetFloat4())
				imgui.AlignTextToFramePadding()
				if bgImage.v then imgui.Text(u8("�����������")) else imgui.TextDisabled(u8"�����������") end
				imgui.SameLine(195)
				if imgui.ColorEdit4("##imageColor", color, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.AlphaBar) then
					cfg.set.imageColor = imgui.ImColor.FromFloat4(color.v[1], color.v[2], color.v[3], color.v[4]):GetU32()
				end
			end
			for k, v in pairs(setTable) do
				if imgui.CollapsingHeader(u8(k)) then
					for sk, sv in pairs(v) do
						-- local color = imgui.ImColor(cfg.colors[sk])
						local color = imgui.ImFloat4(imgui.ImColor(cfg.colors[sk]):GetFloat4())
						imgui.AlignTextToFramePadding()
						imgui.Text(u8(sv))
						imgui.SameLine(195)
						if imgui.ColorEdit4("##" .. sk, color, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.AlphaBar) then
							local newColor = imgui.ImColor.FromFloat4(color.v[1], color.v[2], color.v[3], color.v[4]):GetVec4()
							cfg.colors[sk] = imgui.ImColor(newColor):GetU32()
							colors[sk] = newColor
							if copColor[sk] then
								for _, iv in ipairs(copColor[sk]) do
									colors[iv] = newColor
								end
							end
						end
					end
				end
			end
			imgui.Separator()
			if imgui.Checkbox(u8"������ �����������", bConnectLog) then
				allset.cheat.clog = bConnectLog.v
			end
			if imgui.Checkbox(u8"���������� NPC", bNpcShow) then
				allset.set.npcshow = bNpcShow.v
			end
			imgui.Separator()
			if imgui.Button(u8"��������� ���������", imgui.ImVec2(212, 0)) then
				if notThems then
					inicfg.save(cfg, "..\\resource\\scoreboard\\main\\data.ini")
					notThems = false
				else
					inicfg.save(cfg, "..\\resource\\scoreboard\\" .. allset.set.curTheme .. "\\data.ini")
				end
				inicfg.save(allset, "scoreboard")
				if notf then
					notf.addNotification("��������� ������� ���������", 5)
				end
			end
			imgui.End()
			imgui.PopStyleVar()
		end
		playerCount = 0
		local xOffset = 0
		if bConnectLog.v then
			local x, y = ToScreen(0, 0)
			local w, h = ToScreen(180, 448)
			xOffset = w-x
			imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(4.0, 4.0))
			imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.FirstUseEver)
			imgui.SetNextWindowSize(imgui.ImVec2(w-x, h), imgui.Cond.FirstUseEver)
			imgui.Begin(u8"##connectLogBar", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoBringToFrontOnFocus)
			imgui.SetWindowFontScale(1.05)
			imgui.AlignTextToFramePadding()
			imgui.Text(u8"������ �����������:")
			imgui.SetWindowFontScale(1.0)
			imgui.SameLine(w-x-153)
			imgui.PushItemWidth(150)
			imgui.InputText("##logConFilter", logConFilter)
			if not imgui.IsItemActive() and logConFilter.v:len() == 0 then
				local r, g, b, a = imgui.ImColor(colors[1]):GetRGBA()
				imgui.SameLine(w-x-150)
				imgui.TextColored(imgui.ImColor(r, g, b, 180):GetVec4(), u8"����� �� �������")
			end
			imgui.PopItemWidth()
			imgui.Separator()
			local _, hb = ToScreen(_, 428)
			imgui.BeginChild("##connectLog", imgui.ImVec2(w-x-4, hb))
			imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(1, 2))
			if #logConnect > 0 then
				local fCount = 0
				local viewLog = {}
				for k, v in ipairs(logConnect) do
					if logConFilter.v:len() > 0 then
						if string.find(string.rlower(v), string.rlower(u8:decode(logConFilter.v)), 1, true) then
							table.insert(viewLog, v)
							fCount = fCount + 1
						end
					else
						table.insert(viewLog, v)
					end
				end
				local clipper = imgui.ImGuiListClipper(#viewLog)
				while clipper:Step() do
					for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
						imgui.Text(u8(viewLog[i]))
						if (imgui.IsItemClicked(0) or imgui.IsItemClicked(1)) and (logConFilter.v:len() == 0 or fCount > 0) then
							setClipboardText(viewLog[i])
						end
					end
				end
				if logConFilter.v:len() > 0 and fCount == 0 then
					imgui.Text(u8"���������� �� ������� ...")
				end
			else
				imgui.Text(u8"������ ���� ...")
			end
			if ScrollToButton then
				imgui.SetScrollHere()
				ScrollToButton = false
			end
			imgui.PopStyleVar()
			imgui.EndChild()
			imgui.End()
			imgui.PopStyleVar()
		end
		if allset.set.type == 0 then
			x, y = ToScreen(160, 90)
			w, h = ToScreen(480, 358)
			if bConnectLog.v then
				x = x + xOffset / 2
				w = w + xOffset / 2
			end
		elseif allset.set.type == 1 then
			x, y = ToScreen(130, 60)
			w, h = ToScreen(510, 388)
			if bConnectLog.v then
				x = x + xOffset / 2
				w = w + xOffset / 2
			end
		elseif allset.set.type == 2 then
			x, y = ToScreen(100, 30)
			w, h = ToScreen(540, 418)
			if bConnectLog.v then
				x = x + xOffset / 2
				w = w + xOffset / 2
			end
		elseif allset.set.type == 3 then
			if bConnectLog.v then
				x, y = ToScreen(181, 0)
				w, h = ToScreen(640, 448)
			else
				x, y = ToScreen(0, 0)
				w, h = ToScreen(640, 448)
			end
		end
		imgui.SetNextWindowPos(imgui.ImVec2(x, y), _, imgui.ImVec2(0.0, 0.0))
		imgui.SetNextWindowSize(imgui.ImVec2(w-x , h-y))
		local servername = u8(sampGetCurrentServerName())
		imgui.PushFont(sFont[tonumber(sizesFont[allset.set.fontSize + 1])])
		imgui.Begin(servername, show_main_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoScrollbar + (bTitlebar.v > 0 and imgui.WindowFlags.NoTitleBar or 0))

		if background and bgImage.v then
			local size = imgui.GetWindowSize()
			local bColor = cfg.set.imageColor
			imgui.Image(background, imgui.ImVec2(size.x , size.y-(bTitlebar.v == 0 and 21 or 0)), imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), imgui.ImColor(bColor):GetVec4())
		end
		local snSize
		if bTitlebar.v == 1 then
			snSize = imgui.CalcTextSize(servername)
		end
		imgui.SetCursorPos(imgui.ImVec2(bTitlebar.v == 1 and ((w-x) / 2) - (snSize.x / 2) or 6, bTitlebar.v == 0 and 24 or 3))
		if bTitlebar.v == 1 then
			imgui.Text(servername)
			imgui.Separator()
		end
		imgui.AlignTextToFramePadding()
		imgui.Indent(4); imgui.Text(u8('�����: ' .. sampGetPlayerCount(false) .. ' | �����: ' .. sampGetPlayerCount(true)-1))
		local bText = u8"���������"
		local sText = u8"����� �������"
		local stText = u8"� ���� ������"
		local bSize = imgui.CalcTextSize(bText)
		local sSize = imgui.CalcTextSize(sText)
		local stSize = imgui.CalcTextSize(stText)
		local cColumns = 4
		if streamCheck.v then
			cColumns = cColumns + 2
		end
		if cNType.v == 1 then
			cColumns = cColumns + 1
		end
		if cFilter.v > 0 then
			cColumns = cColumns + 1
		end
		-- Search
		imgui.SameLine(w-x-155)
		imgui.PushItemWidth(150)
		imgui.PushAllowKeyboardFocus(false)
		imgui.InputText("##search", searchBuf, imgui.InputTextFlags.EnterReturnsTrue + imgui.InputTextFlags.CharsNoBlank)
		local iSize = imgui.GetItemRectSize()
		imgui.PopAllowKeyboardFocus()
		imgui.PopItemWidth()
		if not imgui.IsItemActive() and #searchBuf.v == 0 then
			local r, g, b, a = imgui.ImColor(colors[1]):GetRGBA()
			imgui.SameLine(w-x-153)
			imgui.PushStyleColor(imgui.Col.Text, imgui.ImColor(r, g, b, 180):GetVec4())
			imgui.Text(sText)
			imgui.PopStyleColor()
		end
		-- Button
		imgui.SameLine(w-x-(bSize.x + 155 + 9))
		if imgui.Button(bText) then
			show_set_window.v = not show_set_window.v
		end
		-- Combo
		imgui.SameLine(w-x-(bSize.x + 155 + 115 + 9))
		imgui.PushItemWidth(110)
		if imgui.Combo("##PlayerListFilter", cFilter, {u8"��� �����", u8"��� ������", u8"������", u8"������", u8"�����", u8"� ��������"}) then
			allset.set.list = cFilter.v
		end
		imgui.PopItemWidth()
		-- Checkbox
		imgui.SameLine(w-x-(stSize.x + bSize.x + 155 + 115 + 9 + 30))
		if imgui.Checkbox(stText, streamCheck) then
			allset.set.streamcheck = streamCheck.v
		end

		imgui.Columns(cColumns)
		imgui.Separator()
		imgui.NewLine()
		imgui.SameLine(2)
		imgui.SetColumnWidth(-1, 32); imgui.Text('ID'); imgui.NextColumn()
		imgui.SetColumnWidth(-1, w-x-(streamCheck.v and 280 or 160)-(cFilter.v > 0 and 70 or 0)-(cNType.v == 1 and 90 or 0)); imgui.Text(u8'�������'); imgui.NextColumn()
		if cFilter.v > 0 then
			imgui.SetColumnWidth(-1, 70); imgui.Text(u8'������'); imgui.NextColumn()
		end
		if streamCheck.v then
			imgui.SetColumnWidth(-1, 40); imgui.Text(u8'���'); imgui.NextColumn()
			imgui.SetColumnWidth(-1, 80); imgui.Text(u8'���������'); imgui.NextColumn()
		end
		if cNType.v == 1 then
			imgui.SetColumnWidth(-1, 90); imgui.Text(u8'����'); imgui.NextColumn()
		end
		imgui.SetColumnWidth(-1, 70); imgui.Text(u8'����'); imgui.NextColumn()
		imgui.SetColumnWidth(-1, 70); imgui.Text(u8'����'); imgui.NextColumn()
		imgui.Columns(1)
		imgui.Separator()
		imgui.BeginChild("##scroll", imgui.ImVec2(0, 0), false)
		imgui.Columns(cColumns)
		imgui.SetColumnWidth(-1, 32);imgui.NextColumn()
		imgui.SetColumnWidth(-1, w-x-(streamCheck.v and 280 or 160)-(cFilter.v > 0 and 70 or 0)-(cNType.v == 1 and 70 or 0)); imgui.NextColumn()
		if cFilter.v > 0 then
			imgui.SetColumnWidth(-1, 70); imgui.NextColumn()
		end
		if streamCheck.v then
			imgui.SetColumnWidth(-1, 40); imgui.NextColumn()
			imgui.SetColumnWidth(-1, 80); imgui.NextColumn()
		end
		if cNType.v == 1 then
			imgui.SetColumnWidth(-1, 90); imgui.NextColumn()
		end
		imgui.SetColumnWidth(-1, 70);imgui.NextColumn()
		imgui.SetColumnWidth(-1, 70); imgui.NextColumn()
		local local_player_id = getLocalPlayerId()
		if(#searchBuf.v < 1 and not streamCheck.v and cFilter.v < 2) then
			drawScoreboardPlayer(local_player_id)
		else
			if (string.find(sampGetPlayerNickname(local_player_id):lower(), searchBuf.v:lower(), 1, true) or local_player_id == tonumber(searchBuf.v)) and not streamCheck.v and cFilter.v < 2 then
				drawScoreboardPlayer(local_player_id)
			end
		end
		local viewPlayers = {}
		for i = 0, sampGetMaxPlayerId(false) do
			if local_player_id ~= i and sampIsPlayerConnected(i) and (not bNpcShow.v and not sampIsPlayerNpc(i) or bNpcShow.v) then
				local isInStream = sampGetCharHandleBySampPlayerId(i)
				if(#searchBuf.v > 0) then
					if(string.find(sampGetPlayerNickname(i):lower(), searchBuf.v:lower(), 1, true) or i == tonumber(searchBuf.v))then
						if not streamCheck.v or (streamCheck.v and isInStream) then
							local nickname = encoding.UTF8(sampGetPlayerNickname(i))
							local group, gId = getPlayerSGroup(nickname)
							if not ((cFilter.v > 1 and cFilter.v < 5 and gId ~= cFilter.v - 1) or (cFilter.v == 5 and pMarker[i] == nil)) then
								table.insert(viewPlayers, i)
							end
						end
					end
				else
					if not streamCheck.v or (streamCheck.v and isInStream) then
						local nickname = encoding.UTF8(sampGetPlayerNickname(i))
						local group, gId = getPlayerSGroup(nickname)
						if not ((cFilter.v > 1 and cFilter.v < 5 and gId ~= cFilter.v - 1) or (cFilter.v == 5 and pMarker[i] == nil)) then
							table.insert(viewPlayers, i)
						end
					end
				end
			end
		end
		if #viewPlayers > 0 then
			local clipper = imgui.ImGuiListClipper(#viewPlayers)
			while clipper:Step() do
				for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
					drawScoreboardPlayer(viewPlayers[i])
				end
			end
		end

		imgui.Columns(1)
		if(playerCount == 0)then
			imgui.SameLine(5.0); imgui.Text(u8"������ ���� ...")
		end
		imgui.Separator()
		imgui.EndChild()

		imgui.End()
		imgui.PopFont()
	end
end

function getPlayerSGroup(name)
	local name = tostring(name)
	if #name < 1 then
		return nil
	end
	local group, groupId = nil, 0
	if groups.friend[name] then
		group = "����"
		groupId = 1
	elseif groups.admin[name] then
		group = "�����"
		groupId = 2
	elseif groups.enemy[name] then
		group = "����"
		groupId = 3
	end
	return group, groupId
end

function getDistanceToPlayer(playerId)
	if sampIsPlayerConnected(playerId) then
		local result, ped = sampGetCharHandleBySampPlayerId(playerId)
		if result and doesCharExist(ped) then
			local myX, myY, myZ = getCharCoordinates(playerPed)
			local playerX, playerY, playerZ = getCharCoordinates(ped)
			return getDistanceBetweenCoords3d(myX, myY, myZ, playerX, playerY, playerZ)
		end
	end
	return nil
end

function drawScoreboardPlayer(id)
	local pop
	local playerInStream, ped = sampGetCharHandleBySampPlayerId(id)
	local nickname = encoding.UTF8(sampGetPlayerNickname(id))
	local group, gId = getPlayerSGroup(nickname)
	local score = sampGetPlayerScore(id)
	local ping = sampGetPlayerPing(id)
	local color = sampGetPlayerColor(id)
	local health = playerInStream and tostring(sampGetPlayerHealth(id)) or "-"
	local armor = playerInStream and tostring(sampGetPlayerArmor(id)) or "-"
	local model = playerInStream and tostring(getCharModel(ped)) or "-"
	local speed = playerInStream and tostring(math.floor(getCharSpeed(ped))) or "-"
	local distance = getDistanceToPlayer(id)
	local r, g, b = bitex.bextract(color, 16, 8), bitex.bextract(color, 8, 8), bitex.bextract(color, 0, 8)
	local imgui_RGBA = imgui.ImVec4(r / 255.0, g / 255.0, b / 255.0, 1)
	playerCount = playerCount + 1
	imgui.NewLine()
	imgui.SameLine(2)
	if imgui.Selectable(tostring(id), id == focusId, imgui.SelectableFlags.SpanAllColumns + imgui.SelectableFlags.AllowDoubleClick) then
		if imgui.IsMouseDoubleClicked(0) then
			sampSendClickPlayer(id, 0)
			lua_thread.create(function ()
				wait(150)
				toggleScoreboard(false)
			end)
		else
			focusId = focusId == id and -1 or id
		end
	end

	imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(4.0, 3.0))
	if id ~= getLocalPlayerId() and imgui.BeginPopupContextItem() then
		imgui.BeginChild("##pMenu", imgui.ImVec2(150, 138))
		pop = true
		imgui.TextColored(imgui_RGBA, nickname .. "[" .. id .. "]")
		local btnSize = imgui.ImVec2(-0.001, 0.0)
		imgui.Separator()
		if id ~= getLocalPlayerId() then
			bMarkPlayer.v = pMarker[id] and true or false
			if imgui.Checkbox(u8"�������� ������", bMarkPlayer) then
				if pMarker[id] then
					if doesBlipExist(pMarker[id]) then
						removeBlip(pMarker[id])
					end
					mColor[pMarker[id]] = nil
					pMarker[id] = nil
					if notf then
						notf.addNotification("������ ������ " .. nickname .. " ������", 5)
					end
				elseif playerInStream then
					pMarker[id] = addBlipForChar(ped)
					local mCol = alpha255(color)
					changeBlipColour(pMarker[id], mCol)
					mColor[pMarker[id]] = color
					changeBlipDisplay(pMarker[id], 3)
					setBlipAlwaysDisplayOnZoomedRadar(pMarker[id], true)
					if notf then
						notf.addNotification("������ ������ " .. nickname .. " ����������", 5)
					end
				else
					pMarker[id] = -1
					if notf then
						notf.addNotification("������ " .. nickname .. " ������ ��� �����. ������ ����� ���������� ��� �������� ������ � ���� ������.", 5)
					end
				end
				imgui.CloseCurrentPopup()
			end
			if imgui.Button(u8'�������� ���������', btnSize) then
				imgui.CloseCurrentPopup()
				toggleScoreboard(false)
				sampSetChatInputText("/sms " .. id .. " ")
				sampSetChatInputEnabled(true)
			end
		end
		if imgui.Button(u8'���������� �������', btnSize) then
			setClipboardText(nickname)
			imgui.CloseCurrentPopup()
		end
		imgui.Text(u8"������ ������:")
		imgui.PushItemWidth(-0.001)
		_, cSetGroup.v = getPlayerSGroup(nickname)
		if imgui.Combo("##cSetGroup", cSetGroup, {u8"��� ������", u8"����", u8"�����", u8"����"}) then
			if cSetGroup.v == 0 then
				groups.friend[tostring(nickname)] = nil
				groups.admin[tostring(nickname)] = nil
				groups.enemy[tostring(nickname)] = nil
			elseif cSetGroup.v == 1 then
				groups.friend[tostring(nickname)] = true
				groups.admin[tostring(nickname)] = nil
				groups.enemy[tostring(nickname)] = nil
			elseif cSetGroup.v == 2 then
				groups.friend[tostring(nickname)] = nil
				groups.admin[tostring(nickname)] = true
				groups.enemy[tostring(nickname)] = nil
			elseif cSetGroup.v == 3 then
				groups.friend[tostring(nickname)] = nil
				groups.admin[tostring(nickname)] = nil
				groups.enemy[tostring(nickname)] = true
			end
			imgui.CloseCurrentPopup()
		end
		imgui.PopItemWidth()
		imgui.EndChild()
		imgui.EndPopup()
	else
		pop = false
	end
	imgui.PopStyleVar()
	if imgui.IsItemHovered() and not pop and id ~= getLocalPlayerId() then
		imgui.BeginTooltip();
		imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(4.0, 3.0))
		imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(4.0, 2.0))
		imgui.BeginChild("##Test", imgui.ImVec2(157, (tonumber(sizesFont[allset.set.fontSize + 1]) + 2) * 7 + 7), true)
		imgui.Text(nickname .. "[" .. id .. "]")
		imgui.Separator()
		imgui.Text(u8(string.format("� ���� ������: %s", playerInStream and "��" or "���")))
		imgui.Text(u8(string.format("���: %s", playerInStream and (sampIsPlayerPaused(id) and "��" or "���") or "-")))
		imgui.Text(u8(string.format("�����: %s", health)))
		imgui.Text(u8(string.format("�����: %s", armor)))
		imgui.Text(u8(string.format("����: %s", model)))
		imgui.Text(u8(string.format("��������: %s", speed)))
		imgui.EndChild()
		imgui.Separator()
		imgui.PopStyleVar(2)
		imgui.EndTooltip();
	end

	imgui.NextColumn()

	if cNType.v == 0 then
		imgui.TextColored(imgui_RGBA, nickname)
	else
		imgui.Text(nickname)
	end
	imgui.NextColumn()
	if allset.set.list > 0 then
		if gId == 0 then
			imgui.Text(u8("-"))
		else
			local color
			if gId == 1 then
				color = imgui.ImColor(10, 140, 10, 255):GetVec4()
			elseif gId == 2 then
				color = imgui.ImColor(230, 230, 10, 255):GetVec4()
			elseif gId == 3 then
				color = imgui.ImColor(180, 10, 10, 255):GetVec4()
			end
			imgui.TextColored(color, u8(group))
		end
		imgui.NextColumn()
	end
	if streamCheck.v then
		imgui.Text(sampIsPlayerPaused(id) and u8"��" or u8"���"); imgui.NextColumn()
		imgui.Text(string.format("%0.1f", distance)); imgui.NextColumn()
	end
	if cNType.v == 1 then
		imgui.TextColored(imgui_RGBA, "0x" .. string.upper(string.format("%0.8s", bit.tohex(color)))); imgui.NextColumn()
	end
	imgui.Text(tostring(score)); imgui.NextColumn()
	imgui.Text(tostring(ping)); imgui.NextColumn()

	if scrollToId and focusId > -1 and focusId == id then
		scrollToId = false
		imgui.SetScrollHere(0.43)
	end
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		for k, v in pairs(pMarker) do
			if doesBlipExist(v) then
				removeBlip(v)
			end
		end
		if not doesDirectoryExist("moonloader\\config") then
			createDirectory("moonloader\\config")
		end
		if notThems then
			inicfg.save(cfg, "..\\resource\\scoreboard\\main\\data.ini")
			notThems = false
		else
			inicfg.save(cfg, "..\\resource\\scoreboard\\" .. allset.set.curTheme .. "\\data.ini")
		end
		inicfg.save(allset, "scoreboard")
		inicfg.save(groups, "playergroupscoreboard")
	end
end

function string.rlower(s)
	s = s:lower()
	local strlen = s:len()
	if strlen == 0 then return s end
	s = s:lower()
	local output = ''
	for i = 1, strlen do
		 local ch = s:byte(i)
		 if ch >= 192 and ch <= 223 then -- upper russian characters
			  output = output .. russian_characters[ch + 32]
		 elseif ch == 168 then -- �
			  output = output .. russian_characters[184]
		 else
			  output = output .. string.char(ch)
		 end
	end
	return output
end
function string.rupper(s)
	s = s:upper()
	local strlen = s:len()
	if strlen == 0 then return s end
	s = s:upper()
	local output = ''
	for i = 1, strlen do
		 local ch = s:byte(i)
		 if ch >= 224 and ch <= 255 then -- lower russian characters
			  output = output .. russian_characters[ch - 32]
		 elseif ch == 184 then -- �
			  output = output .. russian_characters[168]
		 else
			  output = output .. string.char(ch)
		 end
	end
	return output
end
function SE.onPlayerJoin(id, color, isNpc, nickname)
	if gameInit then
		addConLog(string.format("%s[%d] �����������", nickname, id))
	end
end
function SE.onPlayerQuit(id, reason)
	if gameInit then
		addConLog(string.format("%s[%d] %s", sampGetPlayerNickname(id), id, quitReason[reason+1]))
	end
end
function SE.onRequestClassResponse()
	gameInit = true
end
function SE.onShowDialog()
	gameInit = true
end
function SE.onServerMessage()
	gameInit = true
end
function addConLog(string)
	logConnect[#logConnect+1] = string.format("[%s] %s", os.date("%H:%M:%S"), string)
end
function explode_color(color)
	local a = bit.band(bit.rshift(color, 24), 0xFF)
	local r = bit.band(bit.rshift(color, 16), 0xFF)
	local g = bit.band(bit.rshift(color, 8), 0xFF)
	local b = bit.band(color, 0xFF)
	return a, r, g, b
 end

 function join_color(a, r, g, b)
	local color = b  -- b
	color = bit.bor(color, bit.lshift(g, 8))  -- g
	color = bit.bor(color, bit.lshift(r, 16)) -- r
	color = bit.bor(color, bit.lshift(a, 24)) -- a
	return color
 end

 function convertARGBToRGBA(color)
	local color = tonumber(color)
	local a, r, g, b = explode_color(color)
	return join_color(r, g, b, a)
end

function convertRGBAToARGB(color)
	local color = tonumber(color)
	local r, g, b, a = explode_color(color)
	return join_color(a, r, g, b)
end
function alpha255(color)
	local color = tonumber(color)
	local a, r, g, b = explode_color(color)
	return join_color(r, g, b, 255)
end