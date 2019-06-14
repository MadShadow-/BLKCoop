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
	
	--Init local map stuff
	Mission_InitWeatherGfxSets()
	Mission_InitWeather()
	Mission_InitGroups()	
	Mission_InitLocalResources()
	
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
end
