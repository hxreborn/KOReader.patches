-- 2-footer-zones.lua
-- Dynamic footer alignment for KOReader status items
-- Spreads enabled items across left, center, and right zones
-- Skips alongside progress-bar mode
--
-- Requires: KOReader >= v2025.04-52
-- Tested on: v2025.10-81

local BD = require("ui/bidi")
local CenterContainer = require("ui/widget/container/centercontainer")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local LeftContainer = require("ui/widget/container/leftcontainer")
local ReaderFooter = require("apps/reader/modules/readerfooter")
local RightContainer = require("ui/widget/container/rightcontainer")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local HAIR_SPACE = "\226\128\138"

local gen_map = ReaderFooter.textGeneratorMap
if not gen_map then
	return
end

local function split_zones(n)
	if n <= 0 then
		return 0, 0
	end
	if n == 1 then
		return 0, 1
	end
	if n == 2 then
		return 1, 0
	end
	local s = math.floor(n / 3)
	return s, n - 2 * s
end

local function zone_text(self, modes)
	local parts = {}
	local prev_had_merge
	for _, m in ipairs(modes) do
		local gen = gen_map[m]
		if gen then
			local t, merge = gen(self)
			if t and t ~= "" then
				if self.settings.item_prefix == "compact_items" then
					t = t:gsub("%s", HAIR_SPACE)
				end
				if merge or prev_had_merge then
					if #parts == 0 then
						parts[1] = t
					else
						parts[#parts] = parts[#parts] .. t
					end
					prev_had_merge = merge
				else
					parts[#parts + 1] = t
				end
			end
		end
	end
	for i = 1, #parts do
		parts[i] = BD.wrap(parts[i])
	end
	return table.concat(parts, BD.wrap(self:genSeparator()))
end

local function enabled_items(self)
	local items = {}
	for _, m in ipairs(self.mode_index) do
		if self.settings[m] and m ~= "dynamic_filler" then
			items[#items + 1] = m
		end
	end
	return items
end

-- Restore the original text_container in horizontal_group before tearing down zones
local function free_zones(self)
	if not self.zone_texts then
		return
	end
	if self.dynamic_container and self.horizontal_group and self.text_container then
		for i, child in ipairs(self.horizontal_group) do
			if child == self.dynamic_container then
				self.horizontal_group[i] = self.text_container
				break
			end
		end
	end
	for _, w in pairs(self.zone_texts) do
		w:free()
	end
	self.zone_texts = nil
	self.zone_containers = nil
	self.zone_group = nil
	self.dynamic_container = nil
	self._zone_last_left = nil
	self._zone_last_center = nil
	self._zone_last_right = nil
	self._zone_last_usable = nil
end

local orig_genAlignmentMenuItems = ReaderFooter.genAlignmentMenuItems

ReaderFooter.genAlignmentMenuItems = function(self, value)
	if value == "dynamic" then
		return {
			text = _("Dynamic"),
			checked_func = function()
				return self.settings.align == "dynamic"
			end,
			radio = true,
			callback = function()
				self.settings.align = "dynamic"
				self:refreshFooter(true, true)
			end,
		}
	end
	if value == nil and self.settings.align == "dynamic" then
		return _("dynamic")
	end
	return orig_genAlignmentMenuItems(self, value)
end

local ALIGN_PROBE_VALUES = { "left", "center", "right" }

local function checked_with_align(self, item, value)
	if type(item.checked_func) ~= "function" then
		return false
	end
	local old_align = self.settings.align
	self.settings.align = value
	local ok, checked = pcall(item.checked_func)
	self.settings.align = old_align
	return ok and checked == true
end

local function is_alignment_table(self, sub)
	local found = {}
	for _, item in ipairs(sub or {}) do
		if item.radio then
			local hit, hit_count
			for _, value in ipairs(ALIGN_PROBE_VALUES) do
				if checked_with_align(self, item, value) then
					hit = value
					hit_count = (hit_count or 0) + 1
				end
			end
			if hit_count == 1 and not checked_with_align(self, item, "__simpleui_align_probe__") then
				found[hit] = true
			end
		end
	end
	return found.left and found.center and found.right
end

local function find_alignment_table(self, items)
	for _, item in ipairs(items or {}) do
		local sub = item.sub_item_table
		if sub then
			if is_alignment_table(self, sub) then
				return sub
			end
			local deeper = find_alignment_table(self, sub)
			if deeper then
				return deeper
			end
		end
	end
end

local orig_addToMainMenu = ReaderFooter.addToMainMenu

ReaderFooter.addToMainMenu = function(self, menu_items)
	orig_addToMainMenu(self, menu_items)
	local sb = menu_items.status_bar
	if not sb then
		return
	end
	local align_sub = find_alignment_table(self, { sb })
	if not align_sub then
		return
	end
	local dyn_t = _("Dynamic")
	for _, item in ipairs(align_sub) do
		if item.text == dyn_t then
			return
		end
	end
	align_sub[#align_sub + 1] = self:genAlignmentMenuItems("dynamic")
end

local orig_updateFooterContainer = ReaderFooter.updateFooterContainer

ReaderFooter.updateFooterContainer = function(self)
	free_zones(self)
	orig_updateFooterContainer(self)
	if self.settings.align ~= "dynamic" or self.settings.progress_bar_position == "alongside" then
		return
	end
	if not self.text_container or not self.horizontal_group then
		return
	end

	self.zone_texts = {
		left = TextWidget:new({ text = "", face = self.footer_text_face, bold = self.settings.text_font_bold }),
		center = TextWidget:new({ text = "", face = self.footer_text_face, bold = self.settings.text_font_bold }),
		right = TextWidget:new({ text = "", face = self.footer_text_face, bold = self.settings.text_font_bold }),
	}
	self.zone_containers = {
		left = LeftContainer:new({ dimen = Geom:new({ w = 0, h = self.height }), self.zone_texts.left }),
		center = CenterContainer:new({ dimen = Geom:new({ w = 0, h = self.height }), self.zone_texts.center }),
		right = RightContainer:new({ dimen = Geom:new({ w = 0, h = self.height }), self.zone_texts.right }),
	}
	self.zone_group = HorizontalGroup:new({
		self.zone_containers.left,
		self.zone_containers.center,
		self.zone_containers.right,
	})
	-- Own container avoids upstream's per-refresh resize of text_container.dimen.w
	self.dynamic_container = LeftContainer:new({
		dimen = Geom:new({ w = 0, h = self.height }),
		self.zone_group,
	})
	for i, child in ipairs(self.horizontal_group) do
		if child == self.text_container then
			self.horizontal_group[i] = self.dynamic_container
			break
		end
	end
end

local orig_updateFooterText = ReaderFooter._updateFooterText

ReaderFooter._updateFooterText = function(self, force_repaint, full_repaint)
	orig_updateFooterText(self, force_repaint, full_repaint)
	if self.settings.align ~= "dynamic" or not self.zone_texts then
		return
	end
	local sw = self._saved_screen_width
	if not sw or sw == 0 then
		return
	end

	local items = enabled_items(self)
	local nl, nc = split_zones(#items)
	local zones = { {}, {}, {} }
	for i, m in ipairs(items) do
		if i <= nl then
			zones[1][#zones[1] + 1] = m
		elseif i <= nl + nc then
			zones[2][#zones[2] + 1] = m
		else
			zones[3][#zones[3] + 1] = m
		end
	end

	local lt = zone_text(self, zones[1])
	local ct = zone_text(self, zones[2])
	local rt = zone_text(self, zones[3])

	local usable_w = sw - 2 * self.horizontal_margin
	local zone_w = math.floor(usable_w / 3)
	local geom_changed = self._zone_last_usable ~= usable_w
	local text_changed = force_repaint
		or self._zone_last_left ~= lt
		or self._zone_last_center ~= ct
		or self._zone_last_right ~= rt

	if not text_changed and not geom_changed then
		return
	end

	self.zone_texts.left:setText(lt)
	self.zone_texts.center:setText(ct)
	self.zone_texts.right:setText(rt)
	self._zone_last_left = lt
	self._zone_last_center = ct
	self._zone_last_right = rt

	if geom_changed then
		self.zone_containers.left.dimen.w = zone_w
		self.zone_containers.center.dimen.w = usable_w - 2 * zone_w
		self.zone_containers.right.dimen.w = zone_w
		if self.dynamic_container.dimen then
			self.dynamic_container.dimen.w = usable_w
		end
		self._zone_last_usable = usable_w
	end

	self.zone_group:resetLayout()
	self.horizontal_group:resetLayout()

	if self.footer_content then
		UIManager:setDirty(self, "ui", self.footer_content.dimen)
	end
end
