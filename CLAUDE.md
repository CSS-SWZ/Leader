# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A SourceMod (SourcePawn) plugin for CS:S Zombie Escape servers. It grants one player per round
the "leader" role with visual/communication perks: beacon ring, trail, neon light, world markers,
mass mute, and colorized radio messages. Repo layout mirrors the game server tree, so
`addons/sourcemod/...` is copied verbatim onto a server.

## Build

There is no build script and no test suite — verification means compiling warning-free.

Runtime dependencies: `MUTE` or `PRIORITY` pulls `<basecomm>` (via `voice.sp`) under
`REQUIRE_PLUGIN`, and `basecomm.inc` declares `SharedPlugin … required = 1` — so with either gate
on, **the plugin refuses to load unless `basecomm.smx` is running**. `FLAGS` depends on
sourcebans++ but only softly (`#tryinclude`, and `#undef FLAGS` when the include is absent).

Server assumptions the voice features rely on: `sm_deadtalk 0` and no plugin other than basecomm,
SourceComms++ and SelfMute touching voice state. See "Voice ownership" below.

```sh
cd addons/sourcemod/scripting
"C:/develop/sm-1.13/spcomp.exe" Leader.sp -i"C:/develop/sm-1.13/include" -o<out>/Leader.smx
```

Because of the compile-time feature gates (below), a change touching gated code must be compiled
in more than one combination — at minimum with the gate on and with it commented out in
[Leader.sp](addons/sourcemod/scripting/Leader.sp#L9-L14).

## Architecture

### Single plugin, many files

[Leader.sp](addons/sourcemod/scripting/Leader.sp) is the only translation unit; everything in
`Leader/` is `#include`d as source. The main file holds all shared globals and every SourceMod
forward; forwards do nothing but fan out to module functions (`BeaconOff()`, `CooldownOnRoundStart()`,
`MarkersOnClientDisconnect()`, …). Module files are not libraries and have no include guards —
**include order is dependency order**, since a global must be declared before any file that reads it.

### Compile-time feature gates

`MARKERS`, `MUTE`, `NEON`, `TRAIL`, `COOLDOWN`, `FLAGS`, `PRIORITY` are `#define`d at the top of
`Leader.sp`.
Each optional module self-gates with `#if !defined X → #endinput`, so when off the code is
physically absent, not stubbed. Every call site in `Leader.sp`, `menu.sp` and `config.sp` is
wrapped in `#if defined X`. `FLAGS` additionally depends on an optional `#tryinclude
<sourcebanspp>` and `#undef`s itself when that include is missing
([flags.sp:1-8](addons/sourcemod/scripting/Leader/flags.sp#L1-L8)).

### The leader lifecycle

`CurrentLeader` is a client index, `0` meaning "no leader this round". It is set by `NewLeader()`
and cleared through `HandleAction(ACTION_*)`, which is the single choke point for every way the
role ends (death, disconnect, team switch to spectators/T, round end, voluntary leave, restart).
`HandleAction` always calls `FeaturesOff()` first, then broadcasts the message, then zeroes
`CurrentLeader` — except for `ACTION_LEADER_COME`. Round start (`Event_RoundStart`) also clears it.
Feature modules therefore never need their own "is the leader still valid" bookkeeping.

### Public API

[api.sp](addons/sourcemod/scripting/Leader/api.sp) provides the `leader` library
(`RegPluginLibrary`); the declarations live in
[include/leader.inc](addons/sourcemod/scripting/include/leader.inc), which `Leader.sp` includes
too — natives, `SharedPlugin` block and all. That is safe by design: `AskPluginLoad` (with our
`CreateNative`s) runs at `PluginSys.cpp:966`, before `RunSecondPass` binds natives at L1325, and
`FindOrRequirePluginDeps` skips a `__pl_*` block whose `file` field names the plugin declaring it
(L1104-1106). The catch is that the skip is a filename `strcmp` — **`file = "Leader.smx"` in the
.inc must match whatever the .smx is actually called.**

The module is deliberately **not** gated: every native is registered whatever the `#define`s are,
because a consumer must not crash on a missing native depending on how this plugin was built.

`Leader_OnLeaderSet` / `Leader_OnLeaderRemoved` must pair up exactly once each. That means every
transition of `CurrentLeader` fires one — the three sites are `HandleAction` (its `ACTION_*`
translated to a `LeaderRemoveReason` by `APIOnHandleAction`), `Event_RoundStart` and `NewLeader`
when it overwrites a sitting leader (only reachable via `Leader_SetLeader`), plus `OnPluginEnd`.
Adding a fourth place that writes `CurrentLeader` means adding a forward call there too.

`Leader_OnLeaderRemoved` reports the duration of *that one* leadership, not a per-player total:
summing is the consumer's business, and doing it here would force decisions about map/session
resets and reconnects that belong to a stats plugin.

### Feature-module contract

Beacon, trail, neon, markers, mute and priority all implement the same shape, and adding a new
toggleable feature means adding one function per slot:

| Function | Called from |
| --- | --- |
| `XxxOnKeyValue(key, value)` | `config.sp` SMC dispatch, plus a `Section_Xxx` enum + `Sections[]` entry |
| `XxxParseCommand(cmd)` | `Command_Leader` — the `!leader @<cmd>` chat path |
| `IsXxxActive()` / `XxxToggle()` | `menu.sp` — item label `[+]`/`[-]` and the first-letter `switch` in `LeaderMenu_Handler` |
| `XxxOff()` | `FeaturesOff()` in `Leader.sp` |
| `XxxOnClientDisconnect(client)` | `OnClientDisconnect` |
| `XxxNote()` / `XxxToggleMessage()` | internal — the "you can use `!leader @xxx`" hint, rate-limited by `NOTE_DELAY`/`NOTE_COUNT_MAX` |

Note `LeaderMenu_Handler` dispatches on the **first character** of the item info string, so item
ids must stay unique in their first letter (`Beacon`, `Trail`, `Neon`, `Markers`, `Comms`, `Leave`).
`Event_Callback` in the main file likewise dispatches on `name[0]` and `name[10]` of the event name.

### Voice ownership

[voice.sp](addons/sourcemod/scripting/Leader/voice.sp) is the **only** place in the plugin allowed
to call `SetClientListeningFlags`. Two rules drive its design, both non-obvious:

- SourceMod stores `VOICE_MUTED` in a single integer per client (`g_VoiceFlags`, SDKTools
  `voice.cpp`) with no refcount and no owner — `SetClientListeningFlags` overwrites it wholesale.
  `mute.sp` and `priority.sp` would therefore cancel each other, so `voice.sp` keeps a per-client
  *reason mask* (`REASON_MUTE`, `REASON_PRIORITY`) and clears the flag only when no reason is left.
- **Never call `BaseComm_SetClientMute`.** It raises `BaseComm_OnClientMute`, and SourceComms++
  answers that forward by writing a punishment row into the SourceBans database
  (`sbpp_comms.sp:342-362`) — one row per player per mute. Reading `BaseComm_IsClientMuted` is
  safe; it raises nothing.

Releasing a mute re-reads `BaseComm_IsClientMuted` instead of restoring a saved value, so an admin
mute issued while our mute was held survives it. The opposite direction is covered by
`BaseComm_OnClientMute`: basecomm fires it in the same call stack right after writing the flag
(`basecomm/gag.sp:281-284`), before any game frame elapses, so we re-assert our mute without the
player becoming audible for a single tick.

Layer choice: SelfMute owns the `g_VoiceMap` override matrix and rewrites it on every
spawn/death/team change, whereas `g_VoiceFlags` is touched by basecomm only on explicit admin
action — **as long as `sm_deadtalk` is 0**. Non-zero makes basecomm hook `player_spawn`/
`player_death` and clobber our flag on every death; `PriorityOnConfigsExecuted` logs an error in
that case. Voice flags are also checked *before* the matrix, so SelfMute's `Listen_Yes` cannot undo
our mute.

Timing is engine-bound: `CVoiceGameMgr::UpdateMasks` recomputes at most every 0.3 s
(`voice_gamemgr.cpp`, `UPDATE_INTERVAL`), and `OnClientSpeakingEnd` fires 0.3 s after the last voice
packet — so ducking engages within ~0.3 s and releases in 0.3–0.6 s. `OnClientSpeaking` fires on
*every* voice packet, so `priority.sp` detects the start of speech itself rather than looping over
players many times a second.

### Config parsing

`configs/leader.cfg` is SMC (KeyValues-style), parsed once in `OnPluginStart` by
[config.sp](addons/sourcemod/scripting/Leader/config.sp); a parse failure is a `SetFailState`.
The section enum, the `Sections[]` name table and the gated `case` arms must stay in the same order.
`Markers` is the one nested section: an unrecognized subsection name while inside `Section_Markers`
creates a new marker rather than being an error. Repeated keys accumulate (`Phrases`, `Radio` hold
up to `MAX_PHRASES`/`MAX_RADIO_PHRASES` variants, one picked at random per use).

`configs/leaders.txt` is a flat list of Steam account IDs (`#`-comments allowed), reloaded by
`sm_leaders_reload` and appended to by `sm_leaders_add`/`sm_leaders_add2`; both commands re-run
`OnClientPutInServer` for everyone via `ReloadLeaders()`.

### Localization — hardcoded, not the translations system

There are no `.phrases.txt` files. Every user-facing string exists twice, as RU and EN literals
(module `#define`s, or `switch(IsClientRussian(client))`), selected by
`GetClientLanguage(client) == RussianLanguageId`. The plugin `SetFailState`s at startup if `ru` is
missing from `languages.cfg`. Config-supplied phrases are Russian-only; English falls back to
`FallbackPhrasesEn[]` / `RadioPhrasesEng[]` in code. **Any new message needs both variants.**

Chat output goes through `LeaderPrintToChat` → `SendMessage` in
[chat.sp](addons/sourcemod/scripting/Leader/chat.sp), which prepends the tag and injects `\x07`
hex colors from the `Colors` section; `{C}` inside a message is replaced with `\x07`.

### ZE-map and late-load gating

`is_map_not_ze` is set in `OnMapStart` from the `ze_` map-name prefix. On non-ZE maps precaching
and the download table are skipped entirely, and features whose content is not precached silently
no-op (`Precached` flags in beacon/trail/markers). [late.sp](addons/sourcemod/scripting/Leader/late.sp)
tracks whether the plugin was loaded late *with real players already connected* — precaching then
would show `ERROR` models to those clients, so `TrailPrecache` bails out and beacon/markers only
adopt already-precached content. `LateIsPluginLoadedLate()` is the query; it is cleared on map end.

## Conventions in this repo

The user's global SourcePawn rules apply, with these existing-code exceptions — match the file
you are editing rather than reformatting:

- Only `#pragma newdecls required`; there is no `#pragma semicolon 1`.
- Indentation is 4 spaces in most modules, but tabs in `chat.sp` and `flags.sp`.
- Globals and module statics are PascalCase (`CurrentLeader`, `MarkersCount`), not `snake_case`;
  a few newer ones (`is_map_not_ze`, `leader_loaded`) follow the global rule instead.
- Module-internal state is `static` at file scope; feature functions are entity-first PascalCase
  (`MarkerToggle`, `BeaconPrecache`), matching the global naming rule.
- Bump `version` in `myinfo` once per completed change (SemVer, currently 1.3.4).
