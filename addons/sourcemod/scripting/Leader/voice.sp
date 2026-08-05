#if !defined MUTE && !defined PRIORITY
    #endinput
#endif

#include <basecomm>

// Единая точка записи голосовых флагов.
//
// SourceMod хранит VOICE_MUTED в одном числе на игрока (g_VoiceFlags), без
// счётчика ссылок и без владельца: SetClientListeningFlags перезаписывает его
// целиком. Поэтому две наши фичи (@mute и @priority) не могут писать туда
// напрямую — вторая снимала бы мут первой. Счётчик причин держим здесь.
//
// В basecomm намеренно не ходим: BaseComm_SetClientMute поднимает форвард
// BaseComm_OnClientMute, а SourceComms по нему пишет наказание в базу
// SourceBans (sbpp_comms.sp:342-362) — на каждого игрока при каждом мьюте.
// Читать BaseComm_IsClientMuted при этом безопасно, форвардов он не поднимает.

#define REASON_MUTE     (1 << 0)    // @mute — глушение до конца раунда
#define REASON_PRIORITY (1 << 1)    // @priority — глушение на время речи лидера

static int Reasons[MAXPLAYERS + 1];

void VoiceMute(int client, int reason)
{
    if(Reasons[client] & reason)
        return;

    Reasons[client] |= reason;

    VoiceApply(client);
}

void VoiceUnmute(int client, int reason)
{
    if(!(Reasons[client] & reason))
        return;

    Reasons[client] &= ~reason;

    if(!Reasons[client])
        VoiceApply(client);
}

void VoiceOnBaseCommMute(int client, bool state)
{
    // Админ снял мут, пока действует наша причина — вернуть наш флаг.
    if(!state && Reasons[client])
        VoiceApply(client);
}

void VoiceOnClientDisconnect(int client)
{
    Reasons[client] = 0;
}

static void VoiceApply(int client)
{
    if(!IsClientInGame(client))
        return;

    if(Reasons[client])
    {
        SetClientListeningFlags(client, VOICE_MUTED);
        return;
    }

    // Восстанавливаем не сохранённое ранее значение, а текущее решение
    // basecomm: админ мог замутить игрока, пока действовала наша причина.
    SetClientListeningFlags(client, BaseComm_IsClientMuted(client) ? VOICE_MUTED : VOICE_NORMAL);
}
