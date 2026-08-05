/**
 * Внешний API плагина Leader.
 *
 * Потребителю достаточно скопировать этот файл в scripting/include и подключить:
 *
 *     #undef REQUIRE_PLUGIN
 *     #tryinclude <leader>
 *     #define REQUIRE_PLUGIN
 *
 * Сам плагин подключает файл с #define _leader_provider — тогда объявления
 * нативов и блок зависимости пропускаются, остаются только общие типы.
 */

#if defined _leader_included
    #endinput
#endif
#define _leader_included

/**
 * Причина, по которой игрок перестал быть лидером.
 */
enum LeaderRemoveReason
{
    LeaderRemove_Death = 0,     /**< Погиб или ушёл в зомби */
    LeaderRemove_Disconnect,    /**< Вышел с сервера либо сменилась карта */
    LeaderRemove_RoundDraw,     /**< Ничья или рестарт раунда */
    LeaderRemove_RoundWin,      /**< Люди выиграли раунд */
    LeaderRemove_RoundLose,     /**< Люди проиграли раунд */
    LeaderRemove_Left,          /**< Сложил полномочия сам, снят админом или через Leader_RemoveLeader */
    LeaderRemove_Replaced,      /**< На его место назначен другой игрок через Leader_SetLeader */
    LeaderRemove_Reset          /**< Сброс состояния: старт раунда или выгрузка плагина */
};

/**
 * Вызывается сразу после того, как игрок стал лидером.
 *
 * @param client    Индекс нового лидера.
 */
forward void Leader_OnLeaderSet(int client);

/**
 * Вызывается перед тем, как игрок перестаёт быть лидером.
 *
 * На каждый Leader_OnLeaderSet приходит ровно один Leader_OnLeaderRemoved.
 * При LeaderRemove_Disconnect форвард приходит из OnClientDisconnect, где игрок
 * ещё числится в игре — имя и SteamID прочитать можно.
 *
 * @param client    Индекс бывшего лидера.
 * @param reason    Причина снятия.
 * @param duration  Длительность ИМЕННО ЭТОГО лидерства в секундах. Суммирование
 *                  за карту или за сессию — задача вызывающего плагина.
 */
forward void Leader_OnLeaderRemoved(int client, LeaderRemoveReason reason, float duration);

#if !defined _leader_provider

/**
 * Возвращает действующего лидера.
 *
 * @return          Индекс лидера либо 0, если лидера сейчас нет.
 */
native int Leader_GetLeader();

/**
 * Сколько секунд действующий лидер занимает пост.
 *
 * @return          Время в секундах либо 0.0, если лидера сейчас нет.
 */
native float Leader_GetLeaderTime();

/**
 * Является ли игрок действующим лидером.
 *
 * @param client    Индекс игрока.
 * @return          true, если игрок сейчас лидер.
 * @error           Некорректный индекс игрока.
 */
native bool Leader_IsClientLeader(int client);

/**
 * Назначает игрока лидером в обход проверок доступа и кулдауна — так же, как
 * это делает админская команда sm_leader <target>.
 *
 * Если лидер уже есть, он снимается с причиной LeaderRemove_Replaced.
 *
 * @param client    Индекс игрока.
 * @return          true при успехе; false, если игрок уже лидер, играет за
 *                  зомби или мёртв.
 * @error           Некорректный индекс игрока либо игрок не в игре.
 */
native bool Leader_SetLeader(int client);

/**
 * Снимает действующего лидера с обычным сообщением в чат.
 *
 * @return          true, если лидер был снят; false, если лидера не было.
 */
native bool Leader_RemoveLeader();

/**
 * Есть ли игрок в списке потенциальных лидеров (configs/leaders.txt).
 *
 * @param client    Индекс игрока.
 * @return          true, если игрок может брать лидера.
 * @error           Некорректный индекс игрока.
 */
native bool Leader_IsClientPotentialLeader(int client);

/**
 * Сколько потенциальных лидеров сейчас на сервере.
 *
 * @return          Количество игроков из configs/leaders.txt.
 */
native int Leader_GetPotentialLeadersCount();

public SharedPlugin __pl_leader =
{
    name = "leader",
    file = "Leader.smx",
    #if defined REQUIRE_PLUGIN
    required = 1,
    #else
    required = 0,
    #endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_leader_SetNTVOptional()
{
    MarkNativeAsOptional("Leader_GetLeader");
    MarkNativeAsOptional("Leader_GetLeaderTime");
    MarkNativeAsOptional("Leader_IsClientLeader");
    MarkNativeAsOptional("Leader_SetLeader");
    MarkNativeAsOptional("Leader_RemoveLeader");
    MarkNativeAsOptional("Leader_IsClientPotentialLeader");
    MarkNativeAsOptional("Leader_GetPotentialLeadersCount");
}
#endif

#endif
