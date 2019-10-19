local Image = require "widgets/image"
local Text = require "widgets/text"
local Widget = require "widgets/widget"

local base_atlas = "images/inventoryimages.xml"
local base_atlas_1 = "images/inventoryimages1.xml"
local base_atlas_2 = "images/inventoryimages2.xml"
local minimap_atlas = "minimap/minimap_data.xml"

local NAMES_DEFAULTS = {
	MOON_ALTAR = "MOON_ALTAR",
}

-- 修饰词
local adj_words = {
	"small",
	"medium",
	"large",
	"short",
	"tall",
	"med"
}

-- 包含这些词则不能删形容词
local not_remove = {
	"spore",
	"bravery",
	"halloweenpotion",
	"bundle"
}

local function do_not_remove(str)
	for k,v in ipairs(not_remove) do
		if v == str then
				return true
		end
	end
	return false
end

local function is_adj(str)
	for k,v in ipairs(adj_words) do
		if v == str then
				return true
		end
	end
	return false
end

local function split(str,reps)
	local resultStrList = {}
	string.gsub(str,'[^'..reps..']+',function (w)
			table.insert(resultStrList,w)
	end)
	return resultStrList
end

-- 去除形容词
local function removeadj(str)
	local newstr = str
	local strarr = split(str, "_")
	if strarr ~= nil and next(strarr) ~= nil then
		local canremove = true
		for i = #strarr, 1, -1 do
			if do_not_remove(strarr[i]) then
				canremove = false
				break
			end
		end
		if canremove then
			for i = #strarr, 1, -1 do
				if is_adj(strarr[i]) and strarr[i] ~= "spore" then
						table.remove(strarr, i)
				end
			end
			newstr=""
			for k,v in ipairs(strarr) do
				if k ~= #strarr then
					newstr = newstr..strarr[k].."_"
				else
					newstr = newstr..strarr[k]
				end
			end
		end
	end
	return newstr
end


local ItemTile = Class(Widget, function(self, invitem)
		Widget._ctor(self, "ItemTile")
		self.oitem = invitem
		self.item = TOOMANYITEMS.LIST.prefablist[invitem] or invitem
		self.desc = self:DescriptionInit()

		-- TOOMANYITEMS.LIST.showimagelist[self.item] or
		if TOOMANYITEMS.DATA.listinuse == "building" or TOOMANYITEMS.DATA.listinuse == "animal" or TOOMANYITEMS.DATA.listinuse == "custom" or TOOMANYITEMS.DATA.listinuse or TOOMANYITEMS.DATA.listinuse == "den" == "others" then
			self:TrySetImage()
		else
			if self:IsShowImage() then
				self:SetImage()
			else
				self:SetText()
			end
		end
	end)

function ItemTile:SetText()
	self.image = self:AddChild( Image("images/global.xml", "square.tex") )
	self.image:SetTint(0,0,0,.8)

	self.text = self.image:AddChild(Text(BODYTEXTFONT, 36, ""))
	self.text:SetHorizontalSqueeze(.85)
	self.text:SetMultilineTruncatedString(self:GetDescriptionString(), 2, 68, 8, true)
end

function ItemTile:SetImage()
	local atlas, image = self:GetAsset()

	self.image = self:AddChild(Image(atlas, image, "blueprint.tex"))

end

function ItemTile:TrySetImage()
	local atlas, image = self:GetAsset(true)
	self.image = self:AddChild(Image(atlas, image))
	local w,h = self.image:GetSize()
	if math.max(w,h) < 50 then
		self.image:Kill()
		self.image = nil
		self:SetText()
	end
end

function ItemTile:GetAsset(find)
	if self.item == nil then
		self.item = ""
	end
	local newitem = removeadj(self.item)
	local itemimage = newitem .. ".tex"
	local itematlas = base_atlas
	-- print("[TooManyItems] "..self.item)
	-- if find then
		if STRINGS.CHARACTER_NAMES[newitem] then
			-- local character_item = "skull_"..newitem
			itematlas = minimap_atlas
			itemimage = newitem .. ".png"
			-- print("[TooManyItems] "..self.item.." cc")
		elseif AllRecipes[newitem] and AllRecipes[newitem].atlas and AllRecipes[newitem].image then
			itematlas = AllRecipes[newitem].atlas
			itemimage = AllRecipes[newitem].image
			-- print("[TooManyItems] "..self.item.." re")
		else
			if _G.TheSim:AtlasContains(base_atlas, itemimage) then
				itematlas = base_atlas
				-- print("[TooManyItems] "..self.item.." old")
			elseif _G.TheSim:AtlasContains(base_atlas_1, itemimage) then
				itematlas = base_atlas_1
				-- print("[TooManyItems] "..self.item.." 1")
			elseif _G.TheSim:AtlasContains(base_atlas_2, itemimage) then
				itematlas = base_atlas_2
				-- print("[TooManyItems] "..self.item.." 2")
			else
				-- 名字不匹配的雕像
				if string.find(newitem, "sketch") then
					itemimage = "sketch.tex"
					itematlas = base_atlas
				-- 调料食物，暂时没找到图片叠加，可能是动画文件
				elseif string.find(newitem, "_spice_") then
					local strarr = split(newitem, "_")
					itemimage = strarr[1] .. ".tex"
					if _G.TheSim:AtlasContains(base_atlas, itemimage) then
						itematlas = base_atlas
					elseif _G.TheSim:AtlasContains(base_atlas_1, itemimage) then
							itematlas = base_atlas_1
					else
						itematlas = base_atlas_2
					end
				-- 大理石雕塑
				elseif string.find(newitem, "chesspiece_") and string.find(newitem, "_marble") then
					local strarr = split(newitem, "_")
					itemimage = strarr[1].."_"..strarr[2].. ".tex"
					if _G.TheSim:AtlasContains(base_atlas, itemimage) then
						itematlas = base_atlas
					elseif _G.TheSim:AtlasContains(base_atlas_1, itemimage) then
							itematlas = base_atlas_1
					else
						itematlas = base_atlas_2
					end
				-- 不知道为啥多了一个鹿角
				elseif newitem == "deer_antler" then
					itemimage = "deer_antler1.tex"
					itematlas = base_atlas
				-- 福袋
				elseif newitem == "redpouch_yotp" then
					itemimage = "redpouch_yotp_large.tex"
					itematlas = base_atlas
				-- 石果
				elseif newitem == "rock_avocado_fruit" then
					itemimage = "rock_avocado_fruit_rockhard.tex"
					itematlas = base_atlas_1
				-- 礼物包裹
				elseif newitem == "gift" then
					itemimage = "gift_large1.tex"
					itematlas = base_atlas_1
				-- 礼物包裹
				elseif newitem == "bundle" then
					itemimage = "bundle_large.tex"
					itematlas = base_atlas_1
				else
					local myimagename = "quagmire_"..newitem..".tex"
					if _G.TheSim:AtlasContains(base_atlas, myimagename) then
						itemimage = myimagename
						itematlas = base_atlas
					else
						itemimage = newitem .. ".png"
						itematlas = minimap_atlas
					end
				end
			end
	end

	return itematlas, itemimage
end

function ItemTile:OnControl(control, down)
	self:UpdateTooltip()
	return false
end

function ItemTile:UpdateTooltip()
	self:SetTooltip(self:GetDescriptionString())
end

function ItemTile:IsShowImage()
	local name = TOOMANYITEMS.DATA.listinuse
	if name == "plant" then
		return false
	-- elseif name == "animal" then
	-- 	return false
	-- elseif name == "building" then
	-- 	return false
	elseif name == "boss" then
		return false
	end
	return true
end

function ItemTile:GetDescriptionString()
	return self.desc
end

function ItemTile:DescriptionInit()
	local str = self.item

	if self.item ~= nil and self.item ~= "" then
		local itemtip = string.upper(self.item)
		if STRINGS.NAMES[itemtip] ~= nil and STRINGS.NAMES[itemtip] ~= "" then
			str = STRINGS.NAMES[itemtip]
		end
	end

	if TOOMANYITEMS.LIST.desclist[self.item] then
		str = TOOMANYITEMS.LIST.desclist[self.item]
	end

	if TOOMANYITEMS.LIST.desclist[self.oitem] then
		str = TOOMANYITEMS.LIST.desclist[self.oitem]
	end

	if type(str) == "table" then
		local itemtip = string.upper(self.item)
		if NAMES_DEFAULTS[itemtip] ~= nil then
			str = str[NAMES_DEFAULTS[itemtip]]
		else
			local _, v = next(str)
			str = v
		end
	end

	local strarr = split(self.item, "_")
	-- 调料食物
	if string.find(self.item, "_spice_") then
		local str1 = "Unknown"
		local itemtip = string.upper(strarr[1])
		if STRINGS.NAMES[itemtip] ~= nil and STRINGS.NAMES[itemtip] ~= "" then
			str1 = STRINGS.NAMES[itemtip]
		end
		local subfix = STRINGS.NAMES["SPICE_".. string.upper(strarr[3]).."_FOOD"]
		str = subfmt(subfix, { food = str1 })
	-- 挂饰、彩灯
	elseif string.find(self.item, "winter_ornament_") then
		if #strarr == 4 then
			str = STRINGS.NAMES[string.upper(strarr[1].."_"..strarr[2]..strarr[3])]
		elseif string.find(strarr[3], "light") then
			str = STRINGS.NAMES[string.upper(strarr[1].."_"..strarr[2].."light")]
		else
			str = STRINGS.NAMES[string.upper(strarr[1].."_"..strarr[2])]
		end
	elseif string.find(self.item, "deer_") then
		str = STRINGS.NAMES["DEER_GEMMED"]
  -- 雕像、雕像草图
	elseif string.find(self.item, "chesspiece_") then
		local itemtip = string.upper(strarr[1].."_"..strarr[2])
		if string.find(self.item, "_sketch") then
			if STRINGS.NAMES[itemtip] ~= nil and STRINGS.NAMES[itemtip] ~= "" then
				str = subfmt(STRINGS.NAMES[string.upper(strarr[3])], { item = STRINGS.NAMES[itemtip] })
			end
		else
			if strarr[3] == "stone" then strarr[3] = "cutstone" end
			if STRINGS.NAMES[itemtip] ~= nil and STRINGS.NAMES[itemtip] ~= "" and strarr[3] ~= nil and strarr[3] ~= "" then
				str = STRINGS.NAMES[string.upper(strarr[3])]..STRINGS.NAMES[itemtip]
			end
		end
	end

	return str
end

function ItemTile:OnGainFocus()
	self:UpdateTooltip()
end

return ItemTile