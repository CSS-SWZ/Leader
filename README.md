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

## For other plugins

The plugin registers the `leader` library and exposes a small API: forwards for a leader being
set and removed (the removal carries a reason and how long the leadership lasted), plus natives
to query the current leader, force one, or check who is allowed to lead.

## Languages

Every message exists in Russian and English, picked per player from their game language.
