--[[
	This file handles creation and management of bandits.
	On map there have to exist several script entities, named banditSpawn1, banditSpawn2, ...
															  banditTent1, banditTent2
--]]
BANDITPLAYERID = 5
BANDITCAMPTROOPS = {
	{Entities.CU_BanditLeaderBow1, 4},
	{Entities.CU_BanditLeaderSword2, 4},
	{Entities.CU_Barbarian_LeaderClub2, 4},
	{Entities.CU_AggressiveWolf, 0}
}
function CreateInitialBandits()
	local i = 1
	while IsExisting("banditSpawn"..i) do
		CreateSomeBanditCamp(GetPosition( "banditSpawn"..i), "banditTent"..i)
		i = i + 1
	end
end
function CreateSomeBanditCamp( _spawn, _home)
	local armyId = WarriorArmy:NewArmy( _spawn.X, _spawn.Y, BANDITPLAYERID)
	for k,v in pairs(BANDITCAMPTROOPS) do
		WarriorArmy:AddTroop( armyId, v[1], v[2], _spawn)
	end
	WarriorArmy:AddController( armyId, WarriorArmyController_Defend, { id = armyId, pos = {X = _spawn.X, Y = _spawn.Y}, range = 5000})
end
