--------------------------------------------------------------------------------
-- MapName: XXX
--
-- Author: XXX
--
--------------------------------------------------------------------------------

function GameCallback_OnGameStart() 	
	
	-- Include global tool script functions	
	Script.Load(Folders.MapTools.."Ai\\Support.lua")
	Script.Load( "Data\\Script\\MapTools\\MultiPlayer\\MultiplayerTools.lua" )	
	Script.Load( "Data\\Script\\MapTools\\Tools.lua" )	
	Script.Load( "Data\\Script\\MapTools\\WeatherSets.lua" )
	IncludeGlobals("Comfort")
	
	-- Init  global MP stuff
	--MultiplayerTools.InitResources("normal")
	MultiplayerTools.InitCameraPositionsForPlayers()	
	MultiplayerTools.SetUpGameLogicOnMPGameConfig()
	MultiplayerTools.GiveBuyableHerosToHumanPlayer( 0 )
	
	if XNetwork.Manager_DoesExist() == 0 then		
		for i=1,4,1 do
			MultiplayerTools.DeleteFastGameStuff(i)
		end
		local PlayerID = GUI.GetPlayerID()
		Logic.PlayerSetIsHumanFlag( PlayerID, 1 )
		Logic.PlayerSetGameStateToPlaying( PlayerID )
	end
	
	LocalMusic.UseSet = HIGHLANDMUSIC
	AddPeriodicSummer(10)
	SetupHighlandWeatherGfxSet()
	
	Script.LoadFolder("maps\\user\\blkcoop\\tools")
	Script.Load("maps\\user\\blkcoop\\bandits.lua")
	InstallS5Hook()
	SW.SV.Init()
	InitDebug()
	InitDiplomacy()
	FirstMapAction()
end

function InitDiplomacy()
	Logic.SetPlayerRawName( 5, "Banditen")
	Logic.SetPlayerRawName( 7, "Hodenkobolde")
	Logic.SetPlayerRawName( 8, "Bevölkerung")
	for i = 1, 4 do
		SetHostile( i, 7)
		SetHostile( i, 5)
		SetFriendly( i, 8)
	end
end
function FirstMapAction()
	Camera.ZoomSetFactorMax(2)
	SetupFreeHQBuild()
	WarriorArmy.Init()
	SW.SetAttractionPlaceProvided( Entities.PB_Headquarters1, 75)
	SW.SetAttractionPlaceProvided( Entities.PB_Headquarters2, 100)
	SW.SetAttractionPlaceProvided( Entities.PB_Headquarters3, 125)
	CreateInitialBandits()
	if XNetwork.Manager_DoesExist() == 1 then
		for i = 1, 4 do
			if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID( i) == 1 then
				SpawnPlayer( i)
			end
		end
	else
		SpawnPlayer( 1)
	end
end

function InitDebug()
	Display.SetRenderFogOfWar(0)
	SetEntityName( Logic.CreateEntity( Entities.XD_ScriptEntity, 25500, 45000, 0, 1), "banditSpawn1")
	SetEntityName( Logic.CreateEntity( Entities.XD_ScriptEntity, 25500, 25000, 0, 1), "PlayerSpawn1")
	SetEntityName( Logic.CreateEntity( Entities.XD_ScriptEntity, 25500, 25000, 0, 1), "PlayerSpawn2")
	SetEntityName( Logic.CreateEntity( Entities.XD_ScriptEntity, 25500, 25000, 0, 1), "PlayerSpawn3")
	SetEntityName( Logic.CreateEntity( Entities.XD_ScriptEntity, 25500, 25000, 0, 1), "PlayerSpawn4")
	local g = 100000
	for i = 1, 4 do
		Logic.SetEntityExplorationRange( Logic.CreateEntity(Entities.XD_ScriptEntity, 1, 1, 0, i), 70000)
		Tools.GiveResouces( i, g, g, g, g, g, g)
		ResearchAllUniversityTechnologies( i)
	end
end

function SpawnPlayer( _pId)
	_p = GetPosition( "PlayerSpawn".._pId)
	_serfCount = 8 
	local _,_,sectorID = S5Hook.GetTerrainInfo( _p.X, _p.Y)
	local newRanX, newRanY;
	local rndSector = -1;
	local newEnt, oldEnt
	for i = 1, _serfCount do
		oldEnt = newEnt;
		while(rndSector ~= sectorID) do
			newRanX = _p.X+math.random(-500,500);
			newRanY = _p.Y+math.random(-500,500);
			_, _, rndSector = S5Hook.GetTerrainInfo(newRanX, newRanY);
		end
		newEnt = AI.Entity_CreateFormation( _pId, Entities.PU_Serf, 0, 0, newRanX, newRanY, 0, _p.X, _p.Y, 0)
		Logic.EntityLookAt(newEnt, oldEnt)
	end
	if GUI.GetPlayerID() == _pId then
		Camera.ScrollSetLookAt( _p.X, _p.Y);
	end
end

function SetupFreeHQBuild()
	XGUIEng.ShowWidget("Build_Outpost", 1)
	-- Position of button, row and column
	local col = 4
	local row = 3
	XGUIEng.SetWidgetPosition("Build_Outpost", col*36 - 32, row*36 - 32)
	local costTable = {
		[ResourceType.Gold] = 2500,
		[ResourceType.Wood] = 1500,
		[ResourceType.Stone] = 3000
	}
	SW.SetConstructionCosts( Entities.PB_Headquarters1, costTable)
	FreeHQ_GUIAction_PlaceBuilding = GUIAction_PlaceBuilding
	GUIAction_PlaceBuilding = function( _uc)
		if _uc == UpgradeCategories.Outpost then
			_uc = UpgradeCategories.Headquarters 
			if HasPlayerHQs(GUI.GetPlayerID()) then
				Message("Ihr könnt höchstens ein Hauptquartier haben.")
				Sound.PlayGUISound( Sounds.VoicesMentor_MP_TauntNo, 0)
				return
			end
		end
		FreeHQ_GUIAction_PlaceBuilding( _uc)
	end
	FreeHQ_GUITooltip_ConstructBuilding = GUITooltip_ConstructBuilding
	GUITooltip_ConstructBuilding = function( _uc, _s1, _s2, _a, _b)
		if _uc ~= UpgradeCategories.Outpost then
			FreeHQ_GUITooltip_ConstructBuilding( _uc, _s1, _s2, _a, _b)
			return
		end
		local cString = InterfaceTool_CreateCostString(  SW.GetConstructionCosts( Entities.PB_Headquarters1))
		
		XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, cString)
		XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, "@color:180,180,180,255  Hauptquartier @cr @color:255,255,255,255 "..
			"Hier könnt ihr Leibeigene rekrutieren, Steuern einstellen und den Notstand ausrufen. Das Gebäude dient auch als Lager. Ihr könnt höchstens ein Hauptquartier haben.")		
		XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "")
	end
end

function HasPlayerHQs( _pId)
	if Logic.GetNumberOfEntitiesOfTypeOfPlayer( _pId, Entities.PB_Headquarters1) > 0 then
		return true
	elseif Logic.GetNumberOfEntitiesOfTypeOfPlayer( _pId, Entities.PB_Headquarters2) > 0 then
		return true
	elseif Logic.GetNumberOfEntitiesOfTypeOfPlayer( _pId, Entities.PB_Headquarters3) > 0 then
		return true
	else
		return false
	end
end






