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
	end
end
function CreateSomeBanditCamp( _spawn, _home)
	local armyId = WarriorArmy:NewArmy( _spawn.X, _spawn.Y, BANDITPLAYERID)
	for k,v in pairs(BANDITCAMPTROOPS) do
		WarriorArmy:AddTroop( armyId, v[1], v[2], _spawn)
	end
end

	-- local toSpawn = {
		-- {Entities.PU_LeaderBow3, 8},
		-- {Entities.PU_LeaderBow3, 8},
		-- {Entities.PU_LeaderRifle1, 4},
		-- {Entities.PU_LeaderRifle1, 4},
		-- {Entities.PU_LeaderSword3, 8},
		-- {Entities.PU_LeaderPoleArm3, 8},
		{Entities.PU_LeaderHeavyCavalry2, 3},
	-- }
	-- for i = 1, 3 do
		-- for k,v in pairs( toSpawn) do
			-- WarriorArmy:AddTroop( KAP01_TechArmyIds[i], v[1], v[2])
		-- end
	-- end
	-- KAP01_TechArmyDescs = {
		-- [1] = {
			-- id = KAP01_TechArmyIds[1],
			-- waypoints = { "KAP01_TechWP1", "KAP01_TechWP2", "KAP01_TechWP3"},
			-- cycle = true,
			-- tolerance = 700
		-- },
		-- [2] = {
			-- id = KAP01_TechArmyIds[2],
			-- waypoints = { "KAP01_TechWP2", "KAP01_TechWP3", "KAP01_TechWP1"},
			-- cycle = true,
			-- tolerance = 700
		-- },
		-- [3] = {
			-- id = KAP01_TechArmyIds[3],
			-- waypoints = { "KAP01_TechWP3", "KAP01_TechWP1", "KAP01_TechWP2"},
			-- cycle = true,
			-- tolerance = 700
		-- },
	-- }
	-- for i = 1, 3 do
		-- WarriorArmy:AddController( KAP01_TechArmyIds[i], WarriorArmyController_Waypoints, KAP01_TechArmyDescs[i])
	-- end
	Supply tech city with villagers
	-- local villagerSpawnPos = GetPosition("KAP01_TechWP3")
	-- for i = 1, 12 do
		-- Logic.CreateEntity( Entities.PU_Priest, villagerSpawnPos.X, villagerSpawnPos.Y, 0, 7)
		-- Logic.CreateEntity( Entities.PU_Farmer, villagerSpawnPos.X, villagerSpawnPos.Y, 0, 7)
		-- Logic.CreateEntity( Entities.PU_Miner, villagerSpawnPos.X, villagerSpawnPos.Y, 0, 7)
		-- KAP01_CampFireRemovalTimer = 120
		-- StartSimpleJob("KAP01_RemoveCampfiresJob")
	-- end