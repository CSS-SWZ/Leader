# Leader

A SourceMod plugin for Counter-Strike: Source Zombie Escape servers.

One player per round can take the leader role. The point is to make it obvious who is
leading and to let that person actually be heard: the leader is marked so the whole team can
find them at a glance, their radio calls stand out in chat, and they get some control over
voice comms.

## The role

Players on the whitelist claim the role with `!leader` — first come, first served, one leader
per round. Admins can hand it to someone else.

The role ends on its own when the leader dies, turns zombie, leaves the server or the round
ends; the leader can also step down from the menu. Every one of those moments is announced in
chat with a phrase picked at random from a configurable list, so the same event reads
differently each time.

## What the leader gets

| | |
| --- | --- |
| **Beacon** | A pulsing ring on the ground that follows the leader. |
| **Trail** | A sprite trail left behind as they move. |
| **Neon** | A coloured dynamic light attached to the leader. |
| **Markers** | Props the leader plants in the world to mark a spot — defend here, avoid this, zombie spawn, boss, attack. |
| **Radio** | The standard CS radio commands turn into coloured chat messages attributed to the leader, each with its own set of random phrasings. |
| **Mass mute** | Silences everyone but the leader until the end of the round. |
| **Voice priority** | While the leader is speaking, the chosen teams are muted; they get their microphones back as soon as the leader stops. Which teams — humans, zombies, spectators, admins — is configurable. |
| **Cooldown** | Limits how often the same player can retake the role. |

Each of these is a compile-time module, so a server can ship only the parts it wants. Colours,
phrases, models, radii and command names all come from a config file.

## Using it

| Command | |
| --- | --- |
| `!leader` | Take the role, or open the menu if you already have it. |
| `!leader @<feature>` | Toggle one feature straight from chat, e.g. `!leader @beacon`. |
| `!leaders` | List the players currently on the server who are allowed to lead. |

## API

The plugin registers the `leader` library. Copy `leader.inc` into your `scripting/include` and
depend on it however you like — as a hard requirement, or optionally:

```sourcepawn
#undef REQUIRE_PLUGIN
#tryinclude <leader>
#define REQUIRE_PLUGIN
```

### Forwards

```sourcepawn
forward void Leader_OnLeaderSet(int client);
forward void Leader_OnLeaderRemoved(int client, LeaderRemoveReason reason, float duration);
```

Exactly one `Leader_OnLeaderRemoved` follows every `Leader_OnLeaderSet`, whatever ended the
leadership. `duration` is the length of that one leadership in seconds — if you want a per-player
total, add it up yourself; the plugin deliberately keeps no such tally.

On `LeaderRemove_Disconnect` the forward arrives while the player is still counted as in-game, so
their name and Steam ID are still readable.

### Removal reasons

| | |
| --- | --- |
| `LeaderRemove_Death` | Died or turned zombie. |
| `LeaderRemove_Disconnect` | Left the server, or the map changed. |
| `LeaderRemove_RoundDraw` | Round ended in a draw, or was restarted. |
| `LeaderRemove_RoundWin` | Humans won the round. |
| `LeaderRemove_RoundLose` | Humans lost the round. |
| `LeaderRemove_Left` | Stepped down, was removed by an admin, or `Leader_RemoveLeader`. |
| `LeaderRemove_Replaced` | `Leader_SetLeader` put someone else in the role. |
| `LeaderRemove_Reset` | State reset: round start, or the plugin unloading. |

### Natives

```sourcepawn
native int   Leader_GetLeader();                          // current leader, or 0 if there is none
native float Leader_GetLeaderTime();                      // seconds the current leader has held the role
native bool  Leader_IsClientLeader(int client);
native bool  Leader_SetLeader(int client);                // force, ignoring the whitelist and the cooldown
native bool  Leader_RemoveLeader();
native bool  Leader_IsClientPotentialLeader(int client);  // allowed to lead at all
native int   Leader_GetPotentialLeadersCount();
```

`Leader_SetLeader` fails only if the target is already the leader, is playing zombie, or is dead.
If someone else holds the role, they are removed first with `LeaderRemove_Replaced`.

### Example

```sourcepawn
static float TotalTime[MAXPLAYERS + 1];

public void Leader_OnLeaderRemoved(int client, LeaderRemoveReason reason, float duration)
{
    TotalTime[client] += duration;

    if(reason == LeaderRemove_RoundWin)
        PrintToChatAll("%N led the team to a win, %.0f seconds in charge.", client, duration);
}
```

## Languages

Every message exists in Russian and English, picked per player from their game language.
