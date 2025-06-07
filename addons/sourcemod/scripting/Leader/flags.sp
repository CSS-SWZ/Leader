#if !defined FLAGS
#endinput
#endif

static ConVar FlagsCvar;
static ConVar GroupCvar;

static bool Enable;
static char Group[32];
static int Flags;

bool PreAdminChecked[MAXPLAYERS + 1];
bool LeaderAuthorized[MAXPLAYERS + 1];
bool Loaded[MAXPLAYERS + 1];

void FlagsInit()
{
	FlagsCvar = CreateConVar("sm_leader_flags", "t", "", 0, false, 0.0, false, 0.0);
	GroupCvar = CreateConVar("sm_leader_group", "", "", 0, false, 0.0, false, 0.0);
	ReadFlags();
	GroupCvar.GetString(Group, sizeof(Group));

	FlagsCvar.AddChangeHook(OnConVarFlagsChanged);
	GroupCvar.AddChangeHook(OnConVarFlagsChanged);

	Enable = (Flags || Group[0]);
}

void ReadFlags()
{
	char flags[64];
	FlagsCvar.GetString(flags, sizeof(flags));
	Flags = ReadFlagString(flags);
}

public void OnConVarFlagsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == FlagsCvar)
	{
		ReadFlags();
	}
	else if(convar == GroupCvar)
	{
		convar.GetString(Group, sizeof(Group));
	}
}


void FlagsOnLeaderLoaded(int client)
{
	LeaderAuthorized[client] = true;
	LoadClient(client);
}

void GiveClientPerks(int client)
{
	if (!Enable)
		return;

	if (!PreAdminChecked[client] || !LeaderAuthorized[client])
		return;

	Loaded[client] = true;

	if (!Clients[client].Access)
		return;

	GroupId group;
	if (Group[0] && (group = FindAdmGroup(Group)) != INVALID_GROUP_ID)
	{
		AdminId admin = GetUserAdmin(client);
		if (admin == INVALID_ADMIN_ID)
		{
			admin = CreateAdmin("");
			SetUserAdmin(client, admin, true);
			admin.InheritGroup(group);
		}
		else
		{
			SetUserFlagBits(client, group.GetFlags() | GetUserFlagBits(client));
		}
		SetUserFlagBits(client, group.GetFlags() | GetUserFlagBits(client));
		return;
	}
	SetUserFlagBits(client, Flags | GetUserFlagBits(client));
	return;
}

void LoadClient(int client)
{
	if (!Enable)
		return;

	if (Loaded[client] && PreAdminChecked[client])
		SBPP_CheckLoadAdmin(client);
}

public void OnClientPostAdminFilter(int client)
{
	GiveClientPerks(client);
}

public Action OnClientPreAdminCheck(int client)
{
	PreAdminChecked[client] = true;
	
	if (!Enable)
		return Plugin_Continue;

	if (Loaded[client])
		return Plugin_Continue;

	LoadClient(client);
	return Plugin_Handled;
}

public Action SBPP_OnCheckLoadAdmin(int client)
{
	if (!Enable)
		return Plugin_Continue;

	if (PreAdminChecked[client] && LeaderAuthorized[client])
		return Plugin_Continue;

	return Plugin_Handled;
}

public void FlagsOnClientDisconnect(int client)
{
	PreAdminChecked[client] = false;
	LeaderAuthorized[client] = false;
	Loaded[client] = false;
}