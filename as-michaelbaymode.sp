#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <SteamWorks>

#undef REQUIRE_PLUGIN

new Handle:g_PluginEnabled;

public Plugin:myinfo = 
{
	name = "Michael Bay Mode",
	author = "Gemidyne Softworks",
	description = "",
	version = "1.1",
	url = "https://www.gemidyne.com/"
};

public OnPluginStart()
{
	g_PluginEnabled = CreateConVar("sm_explosions", "0");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnMapStart()
{
	decl String:buffer[64];
	for (new i = 1; i < 10; i++) 
	{
		Format(buffer, sizeof(buffer), "ambient/explosions/explode_%d.wav", i);
		PrecacheSound(buffer);
	}

	for (new i = 1; i <= 3; i++)
	{
		Format(buffer, sizeof(buffer), "vo/npc/male01/runforyourlife0%d.wav", i);
		PrecacheSound(buffer);

		Format(buffer, sizeof(buffer), "weapons/demo_charge_windup%d.wav", i);
		PrecacheSound(buffer);
	}

	for (new i = 1; i <= 5; i++)
	{
		Format(buffer, sizeof(buffer), "player/crit_death%d.wav", i);
		PrecacheSound(buffer);
	}

	for (new i = 1; i <= 6; i++)
	{
		Format(buffer, sizeof(buffer), "misc/octosteps/octosteps_0%d.wav", i);
		PrecacheSound(buffer);
	}

	for (new i = 1; i <= 3; i++)
	{
		Format(buffer, PLATFORM_MAX_PATH, "ambient/cow%d.wav", i);
		PrecacheSound(buffer);
	}

	for (new i = 1; i <= 6; i++)
	{
		Format(buffer, PLATFORM_MAX_PATH, "ambient/dog%d.wav", i);
		PrecacheSound(buffer);
	}


	PrecacheSound("music/radio1.mp3");
	PrecacheSound("vo/canals/shanty_badtime.wav");
	PrecacheSound("ambient/hell/hell_atmos.wav");
	PrecacheSound("player/taunt_shake_it.wav");

	SteamWorks_SetGameDescription("MICHAEL BAY MODE");

	AddNormalSoundHook(Hook_GameSound);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_PluginEnabled) >= 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		for (new i = 1; i <= GetConVarInt(g_PluginEnabled); i++)
		{
			CreateExplosion(client);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (IsClientInGame(client) && GetConVarInt(g_PluginEnabled) >= 1)
	{
		// Eery music for on join...
		EmitSoundToClient(client, "music/radio1.mp3");
		EmitSoundToClient(client, "vo/canals/shanty_badtime.wav");
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (IsClientInGame(client) && GetConVarInt(g_PluginEnabled) >= 1)
	{
		decl String:buffer[64];
		Format(buffer, sizeof(buffer), "vo/npc/male01/runforyourlife0%d.wav", GetRandomInt(1, 3));
		EmitSoundToAll(buffer, client);
	}

	return Plugin_Continue;
}

stock CreateExplosion(client)
{
	CreateParticle(client, "cinefx_goldrush", 5.0);
	CreateParticle(client, "asplode_hoodoo", 5.0);

	env_shake(client, 10000000.0, 10000000.0, 5.0, 10000000.0);

	decl String:buffer[64];
	Format(buffer, sizeof(buffer), "ambient/explosions/explode_%d.wav", GetRandomInt(1, 9));
	EmitSoundToAll(buffer, client);

	new Float:vec[3];

	GetClientEyePosition(client, vec);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)	continue;
		if (GetClientTeam(i) == GetClientTeam(client)) continue;

		new Float:pos[3];
		GetClientEyePosition(i, pos);

		new Float:distance = GetVectorDistance(vec, pos);

		if (distance > 600)	continue;

		new damage = 200; //220
		damage = RoundToFloor(damage * (700 - distance) / 700); //600

		SlapPlayer(i, damage, false);
	}
}

stock CreateParticle(client, String:effect[128], Float:time) 
{
	new Float:strflVec[3];
	GetClientEyePosition(client, strflVec);

	new strIParticle = CreateEntityByName("info_particle_system");
	new String:strName[128];
	if (IsValidEdict(strIParticle)) {
		new Float:strflPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", strflPos);
		TeleportEntity(strIParticle, strflPos, NULL_VECTOR, NULL_VECTOR);

		Format(strName, sizeof(strName), "target%i", client);
		DispatchKeyValue(client, "targetname", strName);

		DispatchKeyValue(strIParticle, "targetname", "tf2particle");
		DispatchKeyValue(strIParticle, "parentname", strName);
		DispatchKeyValue(strIParticle, "effect_name", effect);
		DispatchSpawn(strIParticle);
		SetVariantString(strName);
		AcceptEntityInput(strIParticle, "SetParent", strIParticle, strIParticle, 0);
		//SetVariantString("head");
		//AcceptEntityInput(strIParticle, "SetParentAttachment", strIParticle, strIParticle, 0);
		ActivateEntity(strIParticle);
		AcceptEntityInput(strIParticle, "start");

		CreateTimer(time, killprop_timer, strIParticle);
	}
}

public Action:killprop_timer(Handle:hTimer, any:entity) 
{
	if (IsValidEntity(entity)) 
	{
		AcceptEntityInput(entity, "Kill");
	}

	return Plugin_Stop;
}

stock env_shake(client, Float:amplitude, Float:radius, Float:duration, Float:frequency)
{
	new ent = CreateEntityByName("env_shake");
	new Float:ClientOrigin[3];

	if (DispatchSpawn(ent))
	{
		DispatchKeyValueFloat(ent, "amplitude", amplitude);
		DispatchKeyValueFloat(ent, "radius", radius);
		DispatchKeyValueFloat(ent, "duration", duration);
		DispatchKeyValueFloat(ent, "frequency", frequency);

		SetVariantString("spawnflags 8");
		AcceptEntityInput(ent, "AddOutput");

		AcceptEntityInput(ent, "StartShake", client);

		GetClientAbsOrigin(client, ClientOrigin);

		TeleportEntity(ent, ClientOrigin, NULL_VECTOR, NULL_VECTOR);

		CreateTimer(duration, killprop_timer, ent);
	}
}


public Action:Hook_GameSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (GetConVarInt(g_PluginEnabled) < 1)
	{
		return Plugin_Continue;
	}

	pitch = GetRandomInt(25, 250);

	if (StrContains(sample, "vo/", false) != -1 && StrContains(sample, "vo/npc/male01/runforyourlife", false) == -1)
	{
		if (StrContains(sample, "announce", false) != -1 || StrContains(sample, "ui/", false) != -1) 
		{
			pitch = 50;
			return Plugin_Changed;
		}
		else if (StrContains(sample, "death", false) != -1)
		{
			Format(sample, PLATFORM_MAX_PATH, "player/crit_death%d.wav", GetRandomInt(1, 5));
			return Plugin_Changed;
		}
		else if (StrContains(sample, "ambient", false) != -1)
		{
			Format(sample, PLATFORM_MAX_PATH, "ambient/hell/hell_atmos.wav");
			return Plugin_Changed;
		}
		else
		{
			if (GetRandomInt(0, 10) >= 5)
			{
				Format(sample, PLATFORM_MAX_PATH, "player/crit_death%d.wav", GetRandomInt(1, 5));
			}
			else
			{
				pitch = GetRandomInt(10, 250);
			}
			return Plugin_Changed;
		}
	}

	if (StrContains(sample, "foot", false) != -1)
	{
		Format(sample, PLATFORM_MAX_PATH, "misc/octosteps/octosteps_0%d.wav", GetRandomInt(1, 6));
		return Plugin_Changed;
	}

	if (StrContains(sample, "player", false) != -1)
	{
		if (GetRandomInt(1, 2) == 2)
		{
			Format(sample, PLATFORM_MAX_PATH, "ambient/cow%d.wav", GetRandomInt(1, 3));
		}
		else
		{
			Format(sample, PLATFORM_MAX_PATH, "ambient/dog%d.wav", GetRandomInt(1, 6));
		}

		return Plugin_Changed;
	}

	if (StrContains(sample, "weapons", false) != -1)
	{
		Format(sample, PLATFORM_MAX_PATH, "weapons/demo_charge_windup%d.wav", GetRandomInt(1, 3));
		return Plugin_Changed;
	}
	else if (StrContains(sample, "item", false) != -1)
	{
		Format(sample, PLATFORM_MAX_PATH, "player/taunt_shake_it.wav");
		return Plugin_Changed;
	}

	return Plugin_Changed;
}
