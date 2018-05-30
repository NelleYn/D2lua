local BlinkHelper = {}

BlinkHelper.IsToggled = Menu.AddOption( {"Valera_Shin", "BlinkHelper"}, "Enabled", "")
BlinkHelper.IsBlinkToCursor = Menu.AddOption( {"Valera_Shin", "BlinkHelper"}, "Blink to Cursor", "")
BlinkHelper.BlinkKey = Menu.AddKeyOption( {"Valera_Shin", "BlinkHelper"}, "Blink Key", Enum.ButtonCode.KEY_TAB)
BlinkHelper.sleepers = {}
BlinkHelper.BlinkInPack = false

function BlinkHelper.OnUpdate()
    local hero = Heroes.GetLocal()
	local player = Players.GetLocal()
	if not hero or not Menu.IsEnabled(BlinkHelper.IsToggled) or not Entity.IsAlive(hero) then return end
	if not Menu.IsKeyDown(BlinkHelper.BlinkKey) or not BlinkHelper.SleepCheck(0.05, "updaterate") then return end
	local blink = NPC.GetItem(hero, "item_blink", false)
	if not blink then return end
	if Ability.IsReady(blink) then
		BlinkHelper.UseBlink(hero, blink) 
	end
	if Menu.IsEnabled(BlinkHelper.IsBlinkAbuse) then
		if Ability.GetCooldownTimeLeft(blink) > 2 and Ability.GetCooldownTimeLeft(blink) < 6 then
			local entities = Heroes.GetAll()
			for index, ent in pairs(entities) do
				local enemyhero = Heroes.Get(index)
				if ((not Entity.IsSameTeam(hero, enemyhero) and NPC.IsEntityInRange(hero, enemyhero, NPC.GetAttackRange(enemyhero)) and NPC.IsAttacking(enemyhero)) or BlinkHelper.CheckForModifiers(hero)) and NPC.HasInventorySlotFree(hero, false) and BlinkHelper.SleepCheck(6, "backpack") then
					Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_ITEM, 8, Vector(0,0,0), blink, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, hero)
					Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_ITEM, Menu.GetValue(BlinkHelper.BlinkSlot) - 1, Vector(0,0,0), blink, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, hero)
					BlinkHelper.Sleep(6, "backpack")
					return
				end
			end
		end
	end
	BlinkHelper.Sleep(0.05, "updaterate");
end

function BlinkHelper.UseBlink(hero, blink)
	local castRange = Ability.GetLevelSpecialValueFor(blink, "blink_range") + NPC.GetCastRangeBonus(hero)
	local heroPosition = NPC.GetAbsOrigin(hero)
	local distance = Vector(0,0,0)
	if Menu.IsEnabled(BlinkHelper.IsBlinkToCursor) then 
		distance = Input.GetWorldCursorPos() - heroPosition
	else
		distance = BlinkHelper.InFront(hero, heroPosition, castRange) - heroPosition
	end

	distance:SetZ(0)
	distance:Normalize()
	distance:Scale(castRange - 1)

	local blinkpos = heroPosition + distance
	Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION, hero, blinkpos, blink, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, hero, false, false)
end

function BlinkHelper.CheckForModifiers(hero)
	if not Menu.IsEnabled(BlinkHelper.IsCheckForModifiers) then return false end
	for i=0,28 do
		if NPC.HasModifier(hero, BlinkHelper.Modifiers[i]) then
			return true
		end
	end
	return false
end

function BlinkHelper.InFront(hero, heroPosition, castRange)
	local vec = Entity.GetRotation(hero):GetVectors()
	if vec then
		local x = heroPosition:GetX() + vec:GetX() * castRange
		local y = heroPosition:GetY() + vec:GetY() * castRange
		return Vector(x,y,0)
	end
end

function BlinkHelper.SleepCheck(delay, id)
	if not BlinkHelper.sleepers[id] or (os.clock() - BlinkHelper.sleepers[id]) > delay then
		return true
	end
	return false
end

function BlinkHelper.Sleep(delay, id)
	if not BlinkHelper.sleepers[id] or BlinkHelper.sleepers[id] < os.clock() + delay then
		BlinkHelper.sleepers[id] = os.clock() + delay
	end
end

return BlinkHelper