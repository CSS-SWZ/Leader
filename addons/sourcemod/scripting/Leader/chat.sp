// Размер буфера фиксирован: длина строки формата ничего не говорит о длине
// результата, а SayText2 всё равно режет сообщение по лимиту usermessage.
#define MESSAGE_MAX_LENGTH 512

void LeaderPrintToChat(int client, const char[] message, any ...)
{
	char buffer[MESSAGE_MAX_LENGTH];
	VFormat(buffer, sizeof(buffer), message, 3);
	SendMessage(client, buffer, sizeof(buffer));
}

stock void LeaderPrintToChatAll(const char[] message, any ...)
{
	char buffer[MESSAGE_MAX_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			VFormat(buffer, sizeof(buffer), message, 2);
			SendMessage(i, buffer, sizeof(buffer));
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