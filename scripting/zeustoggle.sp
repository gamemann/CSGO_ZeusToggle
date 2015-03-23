#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

public Plugin:myinfo = {
	name = "[CS:GO] Zeus Toggle",
	description = "Toggle the Zeus on spawn!",
	author = "Roy (Christian Deacon)",
	version = "1.0",
	url = "TheDevelopingCommunity.com"
};

// ConVars
new Handle:g_hDefault = INVALID_HANDLE;

// Cookies
new Handle:g_hClientCookie = INVALID_HANDLE;

// Variables
new bool:bSWZ[MAXPLAYERS+1];	// Spawn With Zeus (SWZ)

public OnPluginStart() {
	// Events
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	// ConVars
	g_hDefault = CreateConVar("sm_zt_default", "0", "0 = Zeus off, 1 = Zeus on");
	
	// Cookies
	g_hClientCookie = RegClientCookie("zeustoggle", "Whether you spawn with a Zeus or not...", CookieAccess_Private);
	
	// Commands
	RegConsoleCmd("sm_zeus", Command_Zeus, "Toggle whether you want the Zeus on spawn or not");
	
	// Config
	AutoExecConfig(true, "sm_zeustoggle");
	
	// Cookies code
	for (new i = MaxClients; i > 0; --i) {
		if (!AreClientCookiesCached(i)) {
			continue;
		}
		
		OnClientCookiesCached(i);
	}
}

// Enable/Disable Zeus Command!
public Action:Command_Zeus(iClient, sArgs) {
	if (!IsClientInGame(iClient)) {
		return Plugin_Handled;
	}
	
	if (bSWZ[iClient]) {
		SetClientCookie(iClient, g_hClientCookie, "1");
		bSWZ[iClient] = false;
		PrintToChat(iClient, "\x02[GFL]\x03Zeus on spawn: \x04OFF");
	} else {
		SetClientCookie(iClient, g_hClientCookie, "2");
		bSWZ[iClient] = true;
		PrintToChat(iClient, "\x02[GFL]\x03Zeus on spawn: \x04ON");
	}
	
	return Plugin_Handled;
}

// Caching
public OnClientCookiesCached(iClient) {
	decl String:sValue[8];
	GetClientCookie(iClient, g_hClientCookie, sValue, sizeof(sValue));
	if (StringToInt(sValue) == 1) {
		// 1 = off
		bSWZ[iClient] = false;
	} else if (StringToInt(sValue) == 2) {
		// 2 = on
		bSWZ[iClient] = true;
	} else {
		// 0, etc = New, so we use default
		if (GetConVarBool(g_hDefault)) {
			bSWZ[iClient] = true;
		} else {
			bSWZ[iClient] = false;
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	// Now to see whether we should give the zeus or not.
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return;
	}
	
	if (bSWZ[iClient]) {
		// We need to simply see if there is a zeus already in the melee slot.
		new iSlot = -1;
		decl String:sWeapon[32];
		
		iSlot = GetPlayerWeaponSlot(iClient, CS_SLOT_KNIFE);
		if (iSlot != INVALID_ENT_REFERENCE) {
			GetEntityClassname(iSlot, sWeapon, sizeof(sWeapon));
		} else {
			sWeapon = "";
		}
		
		if (!StrEqual(sWeapon, "weapon_taser", false)) {
			// Now we know the client doesn't have a zeus.
			RequestFrame(GiveZeus, iClient);
		}
	}
}

public GiveZeus(any:iClient) {
	if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return;
	}
	
	if (bSWZ[iClient]) {
		GivePlayerItem(iClient, "weapon_taser");
	}
}