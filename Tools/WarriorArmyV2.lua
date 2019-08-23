--[[	WarriorArmy V3, angefangen 02.12.18, kompatibel mit V2, braucht S5Hook
		Benötigt:
			Int2Float von bobby / yoq				http://www.siedler-maps.de/forum.php?action=showthread&postid=125506#posting125506
			S5Hook
			VectorLib
			
		WarriorArmy:NewArmy:
			Parameter 1: X-Koordinate der Anfangsposition
			Parameter 2: Y-Koordinate der Anfangsposition
			Parameter 3: Besitzer der Armee
			Rückgabewert: Die ID der Armee, die von anderen Funktionen verlangt wird
		
		WarriorArmy:AddTroop:
			Parameter 1: ID der Armee
			Parameter 2: Truppentyp, z.B. Entities.PU_LeaderBow1
			Parameter 3: Optional: Anzahl der Soldaten, die dem Leader zugewiesen werden, falls nicht angegeben, wird maximale Anzahl verwendet
			Parameter 4: Optional: Gibt die Spawnposition an, falls nicht angegeben, wird aktuelle Position der Armee verwendet
			Kein Rückgabewert
		
		WarriorArmy:GetPosition:
			Parameter 1: ID der Armee
			Rückgabewert: Aktuelle Position der Armee oder Ziel der Armee, falls die Armee tot ist
			
		WarriorArmy:SetPosition:
			Parameter 1: ID der Armee
			Parameter 2: Position, kann EntityID, EntityName oder Positiontable sein
			Verhalten: Die Armee wird sich auf den Weg zu diesem Punkt machen und alles auf dem Weg zerstören
			Kein Rückgabewert
			
		WarriorArmy:AddController:
			Parameter 1: ID der Armee
			Parameter 2: Zuständige Kontrollfunktion
			Parameter 3: Parameter für die Kontrollfunktion
			Mit dieser Funktion übernimmt die Funktion _f die Steuerung über die Armee
			
		WarriorArmy:GetStrength:
			Parameter 1: ID der Armee
			Parameter 2: Optional: Bestimmt über Rückgabe
				1 -> Anzahl der noch lebenden Soldaten(Leader + Soldier)
				2 -> Anzahl der von der Armee besetzten DZ-Plätze
				anderes/nicht angegeben -> Anzahl der lebenden Leader
			Rückgabewert: vgl Parameter 2
			
		WarriorArmy:GetState:
			Parameter 1: ID der Armee
			Rückgabewert: Gibt den Zustand der Armee an, möglich sind:
				WarriorArmy.states.IDLE: Die Armee ist an ihrer Zielposition und kämpft nicht
				WarriorArmy.states.MARCHING: Die Armee läuft zu ihrer Zielposition
				WarriorArmy.states.GATHERING: Die Armee wartet gerade auf langsamere Einheiten
				WarriorArmy.states.FIGHTING: Die Armee gibt jede Formation auf und kämpft, bis im Radius von WarriorArmy.UpdateAreaRange um den Anführers
					keine Gegner mehr zu finden sind; Formationen wurden aufgebrochen
			
		WarriorArmy:SuspendID:
			Parameter 1: ID einer Armee
			Die Armee untersteht nicht mehr der Kontrolle der WarriorArmy, die ID wird recycelt;
			die zugehörigen Truppen bleiben am Leben, sind aber nicht mehr erreichbar

]]

WarriorArmy = {}
--Eine Einheit darf maximal 2 Lvl2-Bogi-Reichweiten von ihrem Leader entfernt sein! 
WarriorArmy.MaxLength = 5000
--Gibt an, ab welcher Entfernung die Armee den Zielpunkt erreicht hat
WarriorArmy.WayPointTolerance = 2000
--Sobald eine Einheit weiter als diese Entfernung von der Armee entfernt ist, wird gewartet
WarriorArmy.ScatteredThreshold = 4000
--Sobald JEDE Einheit maximal diese Entfernung von der Armee hat, gilt die Armee als gesammelt
WarriorArmy.GatheredThreshold = 2000
--Gibt an, wie weit eine Entity neben die ursprüngliche Position laufen darf
WarriorArmy.MoveCommandTolerance = 1000
--Gibt an, wie weit um die Armee herum nach Feinden gesucht wird
WarriorArmy.UpdateAreaRange = 7500
WarriorArmy.states = {
	IDLE = 1,
	MARCHING = 2,
	GATHERING = 3,
	FIGHTING = 4
}
WarriorArmy.Armies = {}
WarriorArmy.ActiveIDs = {}
--Bestimmt, welche EntityTypes von der WarriorArmy als Gegner betrachtet werden
WarriorArmy.Threats = {
	Entities.CU_AggressiveWolf, 			
	Entities.CU_BanditLeaderSword1, 				
	Entities.CU_BanditLeaderSword2,		
	Entities.CU_BanditLeaderBow1,
	Entities.CU_Barbarian_LeaderClub1,
	Entities.CU_Barbarian_LeaderClub2,
	Entities.CU_BlackKnight_LeaderMace1,
	Entities.CU_BlackKnight_LeaderMace2,
	Entities.CU_Evil_LeaderBearman1,
	Entities.CU_Evil_LeaderSkirmisher1,
	Entities.PU_BattleSerf,
	Entities.PU_LeaderBow1,				
	Entities.PU_LeaderBow2,
	Entities.PU_LeaderBow3,
	Entities.PU_LeaderBow4,
	Entities.PU_LeaderCavalry1,
	Entities.PU_LeaderCavalry2,
	Entities.PU_LeaderRifle1,
	Entities.PU_LeaderRifle2,
	Entities.PU_LeaderHeavyCavalry1,
	Entities.PU_LeaderHeavyCavalry2,
	Entities.PU_LeaderPoleArm1,
	Entities.PU_LeaderPoleArm2,
	Entities.PU_LeaderPoleArm3,
	Entities.PU_LeaderPoleArm4,
	Entities.PU_LeaderSword1,
	Entities.PU_LeaderSword2,
	Entities.PU_LeaderSword3,
	Entities.PU_LeaderSword4,
	Entities.PV_Cannon1,
	Entities.PV_Cannon2,
	Entities.PV_Cannon3,
	Entities.PV_Cannon4,
	Entities.CB_Evil_Tower1,
	Entities.PB_Tower2,
	Entities.PB_Tower3,
	Entities.PB_DarkTower2,
	Entities.PB_DarkTower3,
	Entities.PB_VillageCenter1,
	Entities.PB_VillageCenter2,
	Entities.PB_VillageCenter3,
	Entities.PB_Headquarters1,
	Entities.PB_Headquarters2,
	Entities.PB_Headquarters3,
	Entities.CU_VeteranCaptain,
	Entities.CU_VeteranLieutenant,
	Entities.CU_VeteranMajor
}
--Wer will wen tot sehen? Key: Angreifer, Value: Verteidiger
WarriorArmy.Targets = {}
--Helden müssen extra behandelt werden :/
WarriorArmy.Heroes = {
	Entities.PU_Hero1c,
	Entities.PU_Hero2,
	Entities.PU_Hero3,
	Entities.PU_Hero4,
	Entities.PU_Hero5,
	Entities.PU_Hero6,
	Entities.PU_Hero10,
	Entities.PU_Hero11,
	Entities.CU_Evil_Queen,
	Entities.CU_Mary_de_Mortfichet,
	Entities.CU_Barbarian_Hero,
	Entities.CU_BlackKnight
}

function WarriorArmy.Init()
	WarriorArmy.BattleTLs = {
		[TaskLists.TL_BATTLE_POISON] = true,
		[TaskLists.TL_BATTLE_SPECIAL] = true,
		[TaskLists.TL_BATTLE_CROSSBOW] = true,
		[TaskLists.TL_BATTLE_CANNONTOWER] = true,
		--TaskLists[TL_START_BATTLE] = true,
		--TaskLists[TL_BATTLE_SERF_TURN_INTO_SERF] = true,
		[TaskLists.TL_BATTLE_TRAP] = true,
		[TaskLists.TL_BATTLE_BOW] = true,
		[TaskLists.TL_BATTLE_SKIRMISHER] = true,
		[TaskLists.TL_BATTLE_CLAW] = true,
		[TaskLists.TL_BATTLE_RIFLE] = true,
		--TaskLists[TL_SERF_TURN_INTO_BATTLE_SERF] = true,
		[TaskLists.TL_BATTLE_STATIONARY_CANNON] = true,
		[TaskLists.TL_BATTLE_BALISTATOWER] = true,
		[TaskLists.TL_BATTLE_WORKER] = true,
		[TaskLists.TL_BATTLE_VEHICLE] = true,
		[TaskLists.TL_BATTLE_HEROBOW] = true,
		[TaskLists.TL_BATTLE_MACE] = true,
		[TaskLists.TL_BATTLE_POLEARM] = true,
		[TaskLists.TL_BATTLE] = true,
	}
	StartSimpleJob("WarriorArmy_ControlJob")
end
function WarriorArmy.DbgMsg(_string)
	--LuaDebugger.Log(_string)
end
function WarriorArmy.ErrMsg(_string)
	LuaDebugger.Log("WarriorArmy ErrorHandler: ".._string)
end
function WarriorArmy:NewArmy( _posX, _posY, _player)
	local armyId = self:FindID() --search for free ids
	table.insert( self.ActiveIDs, armyId)
	self.Armies[armyId] = {
		player = _player,
		position = { X = _posX, Y = _posY},
		troops = {},
		leader = 0,
		state = self.states.IDLE,
		id = armyId,
		counter = 5,
		inCombat = false,
		controllers = {},
		formation = {},
		deathList = {},
		gracePeriod = 0
	}
	self.DbgMsg("Neue Armee für ".._player.." mit ID "..armyId)
	return armyId
end
function WarriorArmy:FindID()
	local i = 1
	while ( i < 50000) do
		if not self:IstDrin(i, self.ActiveIDs) then
			self.Armies[i] = {}
			return i
		end
		i = i + 1
	end
end
function WarriorArmy:IstDrin( _entry, _table)
	for k,v in pairs(_table) do
		if v == _entry then return true end
	end
	return false
end
function WarriorArmy:SuspendID( _id)
	for k,v in ipairs(self.ActiveIDs) do
		if _id == v then
			table.remove(self.ActiveIDs, k)
			break
		end
	end
end
function WarriorArmy:GetState( _armyId)
	return self.Armies[_armyId].state
end
function WarriorArmy:GetPosition( _armyId)
	local army = self.Armies[_armyId]
	if IsDead(army.leader) then return army.position end
	return GetPosition(army.leader)
end
function WarriorArmy:SetPosition( _armyId, _pos)
	self.Armies[_armyId].position = _pos
	self.Armies[_armyId].counter = 0
end
function WarriorArmy:AddController( _id, _f, _desc)
	table.insert(self.Armies[ _id].controllers, { f = _f, desc = _desc})
end
function WarriorArmy:GetStrength( _id, _flag)
	local myArmy = self.Armies[_id]
	--Logic.GetLeadersGroupAttractionLimitValue(_eID)
	--Logic.LeaderGetNumberOfSoldiers(_eID)
	--Logic.GetAttractionLimitValueByEntityType(_eType)
	--Logic.GetEntityType( _eID)
	--Logic.IsLeader( _eID)
	if _flag == 1 then
		local count = 0
		for k,v in ipairs(myArmy.troops) do
			if not IsDead(v) then
				if Logic.IsLeader(v) then
					count = count + Logic.LeaderGetNumberOfSoldiers( v)
				end
				count = count + 1
			end
		end
		return count
	elseif _flag == 2 then
		local count = 0
		for k,v in ipairs(myArmy.troops) do
			if not IsDead(v) then
				if Logic.IsLeader(v) then
					count = count + Logic.GetLeadersGroupAttractionLimitValue( v)
				else
					count = count + Logic.GetAttractionLimitValueByEntityType( Logic.GetEntityType( v))
				end
			end
		end
		return count
	else
		local count = 0
		for k,v in ipairs(myArmy.troops) do
			if not IsDead(v) then
				count = count + 1
			end
		end
		return count
	end
end
function WarriorArmy_ControlJob()
	for k,v in ipairs(WarriorArmy.ActiveIDs) do
		WarriorArmy:Control(WarriorArmy.Armies[v])
	end
end
function WarriorArmy:Control( _army)
	--Folgender Gedanke:
	-- Armee sammelt sich um einen Hauptmann und versucht, zugewiesene Position zu erreichen
	-- Dabei kann die Armee vier verschiedene Zustände annehmen:
	-- IDLE:
	--	Die Armee hat ihr Ziel erreicht, nichts zu tun.
	-- MARCHING:
	--	Die Armee läuft gerade friedlich zu ihrem Ziel
	-- GATHERING:
	--	Die Armee ist zu verstreut, lasse sammeln
	-- FIGHTING:
	--	Die Armee ist gerade im Kampf
	
	--Lasse Updates nicht zu häufig laufen
	if _army.counter > 0 then
		_army.counter = _army.counter - 1
		return
	end
	--Führe die HighLevelComforts aus
	for k, v in pairs(_army.controllers) do
		v.f( v.desc)
	end
	self.DbgMsg("Befehle Armee ".._army.id.." in State ".._army.state)
	--Pflege das Truppentable; falls true zurückgegeben wird, ist Armee kopflos, kein Management nötig
	if self:MantainArmy( _army) then _army.counter = 5; return end
	--Zeit für Management
	if _army.state == self.states.IDLE then -- Armee ist unbeschäftigt
		if self:IsArmyInCombat( _army.id) then
			_army.state = self.states.FIGHTING
			self:AssignTargets( _army)
			_army.counter = 0
		elseif self:IsScattered( _army) then
			_army.state = self.states.GATHERING
			self:UpdateFormation( _army)
			self:GoIntoFormation( _army)
			_army.counter = 5
		elseif not self:IsAtHome(_army) then
			_army.state = self.states.MARCHING
			self:MoveArmy( _army)
			_army.counter = 5
		else
			self:GoIntoFormation( _army)
			_army.counter = 5
		end
	elseif _army.state == self.states.MARCHING then
		if self:IsArmyInCombat( _army.id) then
			_army.state = self.states.FIGHTING
			self:AssignTargets( _army)
			_army.counter = 0
		elseif self:IsScattered( _army) then
			_army.state = self.states.GATHERING
			self:UpdateFormation( _army)
			self:GoIntoFormation( _army)
			_army.counter = 5
		elseif self:IsAtHome(_army) then
			_army.state = self.states.IDLE
			self:UpdateFormation( _army, true)
			self:GoIntoFormation( _army)
			_army.counter = 5
		else
			self:MoveArmy( _army)
			_army.counter = 2
		end
	elseif _army.state == self.states.GATHERING then
		if self:IsArmyInCombat( _army.id) then
			_army.state = self.states.FIGHTING
			self:AssignTargets( _army)
			_army.counter = 0
		elseif self:IsGathered( _army) then
			_army.state = self.states.MARCHING
			self:MoveArmy( _army)
			_army.counter = 5
		end
	else
		if self:IsArmyInCombat( _army.id) then
			_army.state = self.states.FIGHTING
			self:AssignTargets( _army)
			_army.counter = 0
			_army.gracePeriod = 3
		else
			_army.gracePeriod = _army.gracePeriod - 1
			self:AssignTargets( _army)
			if _army.gracePeriod <= 0 then
				_army.counter = 1
				_army.state = self.states.MARCHING
			end
		end
	end
end
function WarriorArmy:AssignTargets( _army) --TODO: Handle melees better
	local armyPos = GetPosition( _army.leader)
	local enemyPlayerIds = {}
	for i = 1, 8 do
		if Logic.GetDiplomacyState( i, _army.player) == Diplomacy.Hostile and i ~= _army.player then
			table.insert( enemyPlayerIds, i)
		end
	end
	local threats = S5Hook.EntityIteratorTableize( Predicate.OfCategory(EntityCategories.Military),
		Predicate.InCircle( armyPos.X, armyPos.Y, self.UpdateAreaRange),
		Predicate.InSector( Logic.GetSector( _army.leader)),
		Predicate.OfAnyPlayer( unpack(enemyPlayerIds)))
	-- so now we have a nice threat list
	if table.getn(threats) == 0 then return end
	local nearPos = GetPosition(threats[1])
	_army.deathList = {}
	for k,v in pairs( _army.troops) do
		if self:GetRange(v) < 500 then	--melees just attack stuff; TODO: Check if soldiers are attacking aswell, maybe resend command
			Attack( v, nearPos)
		else --ranged dude needs to be smart
			local eId, new = self:GetBiggestThreatInRange( _army, GetPosition(v), self:GetRange(v), threats)
			--if v == 65574 then LuaDebugger.Break() end
			if eId ~= 0 then
				if new then table.insert( _army.deathList, eId) end
				Logic.GroupAttack( v, eId)
			else
				Attack( v, nearPos)
			end
		end
	end
	-- algorithm for ranged dudes:
	--  check if enemy on death list is in range, if it is, attack that mofo to death
	--  if not, go through all threats in range and attack the one with highest threat level
	--  the one attacked is added to death list if not already present there
	--  if there is no nearby enemy, do attack move 
end
function WarriorArmy:GetBiggestThreatInRange( _army, _pos, _range, _list)
	-- first check deathList for baddies
	local threatLvl = 0
	local threatId = 0
	for k,v in pairs(_army.deathList) do
		if self:GetDistance( _pos, GetPosition(v)) <= _range then
			local tLvl = self:GetThreatLevel( v)
			if tLvl > threatLvl then
				threatLvl = tLvl
				threatId = v
			end
		end
	end
	local deathListId = threatId
	local deathListLvl = threatLvl
	threatLvl = 0
	threatId = 0
	-- now compare to surroundings
	for k,v in pairs(_list) do
		if self:GetDistance( _pos, GetPosition(v)) <= _range then
			local tLvl = self:GetThreatLevel( v)
			if tLvl > threatLvl then
				threatLvl = tLvl
				threatId = v
			end
		end
	end
	if deathListLvl < threatLvl then --something more important was found?
		return threatId, true
	elseif deathListId ~= 0 then
		return deathListId
	elseif _army.deathList[1] ~= nil then	--deathList empty and there is no nearby threat? just attack first target
		return _army.deathList[1]
	else
		return _list[1], true
	end
end
WarriorArmy.ThreatLevels = { -- heroes dont need a value, default 100
	[Entities.PV_Cannon1] = 90,
	[Entities.PV_Cannon2] = 90,
	[Entities.PV_Cannon3] = 90,
	[Entities.PV_Cannon4] = 90,
	
	[Entities.PB_DarkTower1] = 80,
	[Entities.PB_DarkTower2] = 80,
	[Entities.PB_DarkTower3] = 80,
	[Entities.PB_Tower1] = 80,
	[Entities.PB_Tower2] = 80,
	[Entities.PB_Tower3] = 80,

	[Entities.PU_LeaderHeavyCavalry1] = 70,
	[Entities.PU_LeaderHeavyCavalry2] = 70,
	
	[Entities.CU_BanditLeaderBow1] = 60,
	[Entities.CU_Evil_LeaderSkirmisher1] = 60,
	[Entities.PU_LeaderBow1] = 60,
	[Entities.PU_LeaderBow2] = 60,
	[Entities.PU_LeaderBow3] = 60,
	[Entities.PU_LeaderBow4] = 60,
	[Entities.PU_LeaderRifle1] = 60,
	[Entities.PU_LeaderRifle2] = 60
}
function WarriorArmy:GetThreatLevel( _eId)
	if Logic.IsHero( _eId) == 1 then
		return 100
	end
	local val = self.ThreatLevels[Logic.GetEntityType(_eId)]
	if val ~= nil then return val end
	return 50
end

function WarriorArmy:GetThreatsInArea( _pos, _range, _pId)
	local enemies = {}
	for i = 1, 8 do
		if Logic.GetDiplomacyState( i, _pId) == Diplomacy.Hostile then
			local j = i
			table.insert( enemies, j)
		end
	end
	local threats = S5Hook.EntityIteratorTableize( Predicate.InCircle(_pos.X, _pos.Y, _range), Predicate.OfAnyPlayer(unpack(enemies)))
	for i = table.getn(threats), -1, 1 do
		if IsDead( threats[i]) then
			table.remove( threats, i)
		end
	end
	return threats
end
function WarriorArmy:GetHeroesInArea( _pos, _range, _pId)	--Gibt nur LEBENDE Helden zurück
	local enemies = {}
	for i = 1, 8 do
		if Logic.GetDiplomacyState( i, _pId) == Diplomacy.Hostile then
			local j = i
			table.insert( enemies, j)
		end
	end
	local heroes = S5Hook.EntityIteratorTableize( Predicate.InCircle(_pos.X, _pos.Y, _range), Predicate.OfCategory( EntityCategories.Hero), Predicate.OfAnyPlayer(unpack(enemies)))
	for i = table.getn(heroes), -1, 1 do
		if IsDead( heroes[i]) then
			table.remove( heroes, i)
		end
	end
	return heroes
end

function WarriorArmy:UpdateFormation( _army, _atHome)
	if _atHome == nil then	--we are not at home? use line from leader to homePoint for formation
		local lpos = GetPosition(_army.leader)
		local line = VectorLib.Rescale( VectorLib.Sub( _army.position, lpos), 100)
		if line.X == 0 and line.Y == 0 then
			line = {X = 100, Y = 0}
		end
		local vertLine = VectorLib.GetOrthVector(line)
		local vertOff = 5
		local horiOff = 3
		_army.formation = {}
		for i = 1, table.getn(_army.troops) do
			local vertIndex = math.mod( i-1, 3)+1	--value between 1 and 3
			local horiIndex = math.ceil(i/3) --value >= 1
			local l = VectorLib.Add( lpos, VectorLib.ScalarProd( vertLine, vertOff*(vertIndex-2)))
			l = VectorLib.Add( l, VectorLib.ScalarProd( line, horiOff*(1-horiIndex)))
			_army.formation[i] = l
			_army.formation[i].angle = 90
		end
	else
		local lpos = GetPosition(_army.leader)
		local line = VectorLib.Rescale( VectorLib.Sub( _army.position, lpos), 100)
		if line.X == 0 and line.Y == 0 then
			line = {X = 100, Y = 0}
		end
		local vertLine = VectorLib.GetOrthVector(line)
		local vertOff = 5
		local horiOff = 3
		_army.formation = {}
		local a = VectorLib.GetAngle( line)
		for i = 1, table.getn(_army.troops) do
			local vertIndex = math.mod( i-1, 3)+1	--value between 1 and 3
			local horiIndex = math.ceil(i/3) --value >= 1
			local l = VectorLib.Add( _army.position, VectorLib.ScalarProd( vertLine, vertOff*(vertIndex-2)))
			l = VectorLib.Add( l, VectorLib.ScalarProd( line, horiOff*(1-horiIndex)))
			_army.formation[i] = l
			_army.formation[i].angle = a
		end
	end
end
function WarriorArmy:GoIntoFormation( _army)
	local leaderPos = GetPosition(_army.leader)
	local nMax = table.getn(_army.formation)
	for i = 1, table.getn(_army.troops) do
		if i <= nMax then
			self:MoveEntity( _army.troops[i], _army.formation[i], _army.formation[i].angle)
		else
			self:MoveEntity( _army.troops[i], leaderPos)
		end
	end
end
function WarriorArmy:MoveArmy( _army)
	for k,v in pairs(_army.troops) do
		self:MoveEntity( v, _army.position)
	end
end
function WarriorArmy:MoveEntity( _eId, _pos, _angle)
	local currPos = GetPosition( _eId)
	-- if position is reached do nothing
	if self:GetDistance( currPos, _pos) < 100 then
		if _angle ~= nil then Logic.RotateEntity( _eId, _angle) end
		return
	end
	local targetX = Int2Float( Logic.GetEntityScriptingValue( _eId, 8))
	local targetY = Int2Float( Logic.GetEntityScriptingValue( _eId, 9))
	-- current target position equals position given from outside? do nothing
	if self:GetDistance( _pos, {X = targetX, Y = targetY}) < 50 then return end
	-- something off? send new command
	Attack( _eId, _pos)
end
function WarriorArmy:IsGathered( _army)	-- returns true if army is gathered again
	local leaderPos = GetPosition(_army.leader)
	for k,v in pairs(_army.troops) do
		if self:GetDistance( leaderPos, GetPosition(v)) > self.GatheredThreshold then
			return false
		end
	end
	return true
end
function WarriorArmy:IsScattered( _army)	-- returns true if army is to much scattered around
	local leaderPos = GetPosition(_army.leader)
	for k,v in pairs(_army.troops) do
		if self:GetDistance( leaderPos, GetPosition(v)) > self.ScatteredThreshold then
			return true
		end
	end
	return false
end
function WarriorArmy:IsAtHome( _army)
	if WarriorArmy:GetDistance( GetPosition(_army.leader), _army.position) < WarriorArmy.WayPointTolerance then
		return true
	end
	return false
end
function WarriorArmy:GetDistance( _p1, _p2)
	local deltaX = _p1.X - _p2.X
	local deltaY = _p1.Y - _p2.Y
	return math.sqrt(deltaX*deltaX + deltaY*deltaY)
end
function WarriorArmy:MantainArmy( _army)
	--Movementspeed Int2Float(Logic.GetEntityScriptingValue(65574,31))
	for i = table.getn(_army.troops),1,-1 do
		if IsDead(_army.troops[i]) then
			table.remove(_army.troops, i)
		end
	end
	if not IsDead(_army.leader) then return end
	local bestIndex = 0
	local bestVal = 0
	for i = 1, table.getn(_army.troops) do
		if self:GetMovementSpeed(_army.troops[i]) > bestVal then
			bestIndex = i
			bestVal = self:GetMovementSpeed(_army.troops[i])
		end
	end
	if bestIndex == 0 then return true end
	_army.leader = _army.troops[bestIndex]
	self.DbgMsg("Neuer Befehlshaber: ".._army.leader.." mit MS "..bestVal)
end
function WarriorArmy:GetMovementSpeed( _id)
	return Int2Float(Logic.GetEntityScriptingValue( _id, 31))
end
function WarriorArmy:GetRange( _id)
	return Int2Float(Logic.GetEntityScriptingValue( _id, 49))
end
function WarriorArmy:GetEntityCombatState( _id)	--returns 2 if in combat, 1 if starting combat and 0 if not in combat
	local tl = Logic.GetEntityScriptingValue( _id, -22)
	if tl == TaskLists.TL_START_BATTLE then
		return 1
	elseif self.BattleTLs[tl] then
		return 2
	else
		return 0
	end
end
function WarriorArmy:IsArmyInCombat( _armyId)
	local t = self.Armies[_armyId]
	for k,v in pairs(t.troops) do
		if WarriorArmy:GetEntityCombatState(v) ~= 0 then
			return true
		end
	end
	return false
end
function WarriorArmy:AddTroop( _id, _leader, _nsoldier, _pos)
	--Logic.LeaderGetSoldiersType( _leaderID)
	--Logic.LeaderGetMaxNumberOfSoldiers( _leaderID)
	--Logic.LeaderGetOneSoldier( LeaderID ) schnappt einen Soldaten in der Nähe und fügt ihn dem Leader hinzu
	--Logic.CreateEntity( SoldierType, LeaderX, LeaderY, 0, LeaderPlayerID )
	if _pos == nil then
		_pos = self:GetPosition(_id)
	end
	local player = WarriorArmy.Armies[_id].player
	local leaderId = Logic.CreateEntity( _leader, _pos.X, _pos.Y, 0, player)
	local maxSoldiers = Logic.LeaderGetMaxNumberOfSoldiers(leaderId)
	local soldierType = Logic.LeaderGetSoldiersType(leaderId)
	if _nsoldier == nil then
		_nsoldier = maxSoldiers
	end
	for i = 1, _nsoldier do
		Logic.CreateEntity( soldierType, _pos.X, _pos.Y, 0, player)
		Logic.LeaderGetOneSoldier(leaderId)
	end
	Logic.LeaderChangeFormationType( leaderId, 4)
	table.insert(self.Armies[_id].troops, leaderId)
	Logic.GroupAttack( leaderId, leaderId)	-- start some attack to set SV 49 == attack range
	Move( leaderId, _pos) -- start movement directly after to not mess up the task list and army itself
end

--Kontrollfunktionen für die WarriorArmy
--[[		TODO
		Jagt keine Helden
		Jagt NUR nach Militäreinheiten / Türmen
		Sucht nicht optimales/ nahes Ziel aus
	.id ist die ID der Armee
	.delay bestimmt, wie viele Sekunden nach der Vernichtung die neue Armee auftaucht
	.spawnPoint bestimmt, wo die Armee entsteht
	.spawnGenerator bestimmt, von welcher Entity der Respawn abhängt
	.spawnTypes beschreibt, welche Entities jeweils gespawnt werden
		Beispieleintrag: { type = Entities.PU_LeaderBow1, n = 3}
		n-Eintrag ist optional, gibt Anzahl der Soldaten an
	.radius bestimmt, in welchem Radius die Armee nach Feinden sucht, Zentrum ist der SpawnPoint
	
	Muss jede Sekunde aufgerufen werden
	Gibt true zurück, sobald die Armee ENDGÜLTIG besiegt ist
	INTERN:
	.state | 1 = TOT | 2 = AUF JAGD | 3 = IDLE
	.cd
	.target
]]
function WarriorArmy_RespawnController( _desc)   --Aufgeschoben
	if IsDead( _desc.spawnGenerator) then
		_desc.spawnGenerator = {}
		if WarriorArmy:GetStrength( _desc.id) == 0 then
			return true
		end
	end
	--Erster Aufruf?
	if _desc.state == nil then
		_desc.cd = _desc.delay
		_desc.state = 3
		_desc.target = 0
		WarriorArmy:SetPosition( _desc.id, _desc.spawnPoint)
		for k,v in pairs(_desc.spawnTypes) do
			if v.n ~= 0 then
				WarriorArmy:AddTroop( _desc.id, v.type, v.n)
			else
				WarriorArmy:AddTroop( _desc.id, v.type)
			end
		end
	else
		if _desc.state == 1 then	--Du bist TOT
			_desc.cd = _desc.cd - 1
			if _desc.cd < 1 and IsAlive(_desc.spawnGenerator) then
				_desc.state = 3
				_desc.cd = _desc.delay
				_desc.target = 0
				WarriorArmy:SetPosition( _desc.id, _desc.spawnPoint)
				for k,v in pairs(_desc.spawnTypes) do
					if v.n ~= 0 then
						WarriorArmy:AddTroop( _desc.id, v.type, v.n)
					else
						WarriorArmy:AddTroop( _desc.id, v.type)
					end
				end
			end
		elseif _desc.state == 2 then --Du bist ON THE HUNT
			if IsDead( _desc.target) then
				_desc.target = 0
				WarriorArmy:SetPosition( _desc.id, _desc.spawnPoint)
				_desc.state = 3
			elseif WarriorArmy:GetStrength( _desc.id) == 0 then --Jetzt bist du tot
				_desc.target = 0
				_desc.state = 1
				_desc.cd = _desc.delay
			else
				WarriorArmy:SetPosition( _desc.id, _desc.target)
			end
		else --Du bist IDLE
			if WarriorArmy:GetStrength( _desc.id) == 0 then
				_desc.target = 0
				_desc.state = 1
				_desc.cd = _desc.delay
			else
				local list = WarriorArmy:GetThreatsInArea( _desc.spawnPoint, _desc.radius, WarriorArmy.Armies[_desc.id].player)
				if list[1] ~= nil then
					_desc.target = list[1]
					_desc.state = 2
				end
			end
		end
	end
end
--[[	Verteidige einen Bereich!
	Parameter:
		.id			ID der Armee, die gesteuert werden soll
		.pos 		Zentrum des zu verteidigenden Gebiets, muss Positiontable sein
		.range		Radius um .pos, der verteidigt werden soll
	INTERN:
		.state 		Zustand, 1 = IDLE, 2 = Angreifer gesichtet
		.target 	Aktuelles Ziel der Armee
]]
function WarriorArmyController_Defend( _desc)
	--Erster Aufruf?
	if _desc.state == nil then
		_desc.state = 1
		_desc.target = 0
	end
	if _desc.state == 1 then
		WarriorArmy:SetPosition( _desc.id, _desc.pos)
		--Suche nach Feinden im Gebiet
		for i = 1, 8 do
			if Logic.GetDiplomacyState( i, WarriorArmy.Armies[_desc.id].player) == Diplomacy.Hostile then
				local enemies = WarriorArmy:GetThreatsInArea( _desc.pos, _desc.range, WarriorArmy.Armies[_desc.id].player)
				local hostileHeroes = WarriorArmy:GetHeroesInArea( _desc.pos, _desc.range, WarriorArmy.Armies[_desc.id].player)
				local target = 0
				local mySector = Logic.GetSector( WarriorArmy.Armies[_desc.id].leader)
				for k,v in pairs( hostileHeroes) do
					if Logic.GetSector( v) == mySector then
					--if true then
						target = v
						break
					end
				end
				if target == 0 then
					for k,v in pairs( enemies) do
						if Logic.GetSector( v) == mySector then
						--if true then
							target = v
							break
						end
					end
				end
				if target ~= 0 then
					_desc.target = target
					_desc.state = 2
				end
			end
		end
	else
		if IsDead( _desc.target) then
			_desc.target = 0
			_desc.state = 1
		else
			if Logic.GetSector(_desc.target) ~= Logic.GetSector(WarriorArmy.Armies[_desc.id].leader) then
			--if false then
				_desc.target = 0
				_desc.state = 1
			else
				if WarriorArmy:GetStrength( _desc.id) == 0 then
					_desc.target = 0
					_desc.state = 1
				else
					local pos = GetPosition( _desc.target)
					WarriorArmy:SetPosition( _desc.id, pos)
				end
			end
		end
	end
end
--[[ Laufe diese WayPoints ab!
	Parameter:
		.id			ID der Armee
		.waypoints	Table mit den Waypoints, Beispiel:
			{"WP1","WP2","WP3","WP4"}
		.cycle		soll, wenn der letzte WP erreicht wurde, von vorne angefangen werden?
		.tolerance	ab welcher Distanz ist die Armee am WP angekommen?
	INTERN:
		.currentWP	Welcher WP ist gerade das Ziel?
		.maxWP		Wie groß ist das .waypoints-table?
]]
function WarriorArmyController_Waypoints(_desc)
	if WarriorArmy:GetStrength( _desc.id) == 0 then --Tote Armee -> Zurück auf Anfang
		_desc.currentWP = 1
		return
	end
	if _desc.currentWP == nil then	--Erster Aufruf
		_desc.currentWP = 1
		for k,v in pairs(_desc.waypoints) do
			if type(v) ~= "table" then
				v = GetPosition(v)
			end
		end
	end
	local pos = WarriorArmy:GetPosition( _desc.id)
	if WarriorArmy:GetDistance( pos, _desc.waypoints[_desc.currentWP]) < _desc.tolerance then
		if _desc.currentWP < table.getn(_desc.waypoints) then	--Ziel erreicht, es geht aber weiter
			_desc.currentWP = _desc.currentWP + 1
		else
			if _desc.cycle == true then
				_desc.currentWP = 1
			end
		end
	end
	WarriorArmy:SetPosition( _desc.id, _desc.waypoints[_desc.currentWP])
end
--[[	Respawn von Armeen
	Parameter:
		.id 			ID der Armee
		.delay 			so viele Sekunden nach der Vernichtung taucht neue Armee auf
		.spawnPoint 	bestimmt, wo die Armee entsteht, muss Positiontable sein
		.spawnGenerator	bestimmt, von welcher Entity der Respawn abhängt
		.spawnTypes 	beschreibt, welche Entities jeweils gespawnt werden
			Beispieleintrag: { type = Entities.PU_LeaderBow1, n = 3}
			n-Eintrag ist optional, gibt Anzahl der Soldaten an
	INTERN:
		.cd 			wie lange ist es noch bis zum Respawn
		.state			1 = TOT | 2 = NICHT TOT
]]
function WarriorArmyController_Respawn( _desc)
	if IsDead(_desc.spawnGenerator) then
		return true
	end
	--Erster Aufruf?
	if _desc.state == nil then
		_desc.state = 2
		WarriorArmy:SetPosition( _desc.id, _desc.spawnPoint)
		for k,v in pairs( _desc.spawnTypes) do
			if v.n ~= nil then
				WarriorArmy:AddTroop( _desc.id, v.type, v.n)
			else
				WarriorArmy:AddTroop( _desc.id, v.type)
			end
		end
		_desc.cd = _desc.delay
	end
	if _desc.state == 1 then --tot
		_desc.cd = _desc.cd - 1
		if _desc.cd < 1 then
			_desc.cd = _desc.delay
			_desc.state = 2
			WarriorArmy:SetPosition( _desc.id, _desc.spawnPoint)
			for k,v in pairs( _desc.spawnTypes) do
				if v.n ~= nil then
					WarriorArmy:AddTroop( _desc.id, v.type, v.n)
				else
					WarriorArmy:AddTroop( _desc.id, v.type)
				end
			end
		end
	else
		if WarriorArmy:GetStrength( _desc.id) == 0 then		--Ab jetzt tot
			_desc.state = 1
			_desc.cd = _desc.delay
		end
	end
end



function GetDistance(_pos1,_pos2)
    if (type(_pos1) == "string") or (type(_pos1) == "number") then
        _pos1 = GetPosition(_pos1);
    end
    assert(type(_pos1) == "table");
    if (type(_pos2) == "string") or (type(_pos2) == "number") then
        _pos2 = GetPosition(_pos2);
    end
    assert(type(_pos2) == "table");
    local xDistance = (_pos1.X - _pos2.X);
    local yDistance = (_pos1.Y - _pos2.Y);
    return math.sqrt((xDistance^2) + (yDistance^2));
end

function Int2Float(inum)
    if(inum == 0) then
        return 0
    end

    local sign = 1
    if(inum < 0) then
        inum = 2147483648 + inum
        sign = -1
    end

    local frac = math.mod(inum, 8388608)
    local exp = (inum-frac)/8388608 - 127
    local fraction = 1
    local fracVal = 0.5
    local bitVal = 4194304
    for i = 23, 1, -1 do
        if(frac - bitVal) > 0 then
            fraction = fraction + fracVal
            frac = frac - bitVal
        end
        bitVal = bitVal / 2
        fracVal = fracVal / 2
    end
    fraction = fraction + fracVal * frac * 2
    return math.ldexp(fraction, exp) * sign
end
