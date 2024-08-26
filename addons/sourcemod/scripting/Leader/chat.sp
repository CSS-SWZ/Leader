void LeaderPrintToChat(int client, const char[] message, any ...)
{
	int len = strlen(message) + 255;
	char[] buffer = new char[len];
	VFormat(buffer, len, message, 3);
	SendMessage(client, buffer, len);
}

stock void LeaderPrintToChatAll(const char[] message, any ...)
{
	int len = strlen(message) + 255;
	char[] buffer = new char[len];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			VFormat(buffer, len, message, 2);
			SendMessage(i, buffer, len);
		}
	}
}

void SendMessage(int client, char[] message, int size)
{
	Format(message, size, "\x01\x07%s%s \x07%s%s", Colors[COLOR_TAG][1], TAG, Colors[COLOR_DEFAULT][1], message);
	ReplaceString(message, size, "{C}", "\x07");
	Handle msg = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWrite bf = UserMessageToBfWrite(msg);
	bf.WriteByte(client);
	bf.WriteByte(true);
	bf.WriteString(message);
	EndMessage();
}