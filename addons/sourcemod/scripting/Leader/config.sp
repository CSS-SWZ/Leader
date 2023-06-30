// CONFIG LOAD

#define SECTION_STARTED

enum
{
    Section_None = -1,
    Section_Phrases,
    Section_Colors,
    Section_Beacon,
    Section_Radio,
    Section_RadioColors,

    #if defined TRAIL
    Section_Trail,
    #endif

    #if defined NEON
    Section_Neon,
    #endif

    #if defined MARKERS
    Section_Markers,
    #endif

    #if defined MUTE
    Section_Mute,
    #endif

    Section_Total
}

static bool SectionLoaded[Section_Total];

static const char Sections[][] = 
{
    "Phrases",
    "Colors",
    "Beacon",
    "Radio",
    "RadioColors",

    #if defined TRAIL
    "Trail",
    #endif

    #if defined NEON
    "Neon",
    #endif
    
    #if defined MARKERS
    "Markers",
    #endif

    #if defined MARKERS
    "Mute",
    #endif

    "Total"
}

static const char ColorsKeys[][] = 
{
    "tag",
    "name",
    "default",
    "radio"
}

static const char ActionsKeys[][] = 
{
    "death",
    "disconnect",
    "draw",
    "win",
    "lose",
    "come",
    "leave"
}

static int CurrentSection = Section_None;

stock void LoadConfig()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/leader.cfg");

    if(!ParseConfigFile(path))
        SetFailState("Cant parse config \"%s\"", path);
}

stock bool ParseConfigFile(const char[] path)
{
    SMCParser smc = new SMCParser();
    smc.OnEnterSection = SMC_NewSection;
    smc.OnKeyValue = SMC_KeyValue;
    smc.OnLeaveSection = SMC_EndSection;

    SMCError result = smc.ParseFile(path);
    delete smc;

    if(result !=  SMCError_Okay)
        return false;
    
    return true;
}

public SMCResult SMC_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
    int section = SMC_GetSection(name);

    switch(section)
    {
        case Section_None:
        {
            switch(CurrentSection)
            {
                case Section_None: return SMCParse_Halt;
                #if defined MARKERS
                case Section_Markers:
                {
                    MarkersOnNewSection(name);
                }
                #endif
            }
        }
        default:
        {
            CurrentSection = section;
        }
    }
    
    return SMCParse_Continue;
}

public SMCResult SMC_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
    switch(CurrentSection)
    {
        case Section_Phrases:
        {
            int index = SMC_GetAction(key);

            if(index == -1)
                return SMCParse_Continue;

            int count = PhrasesCount[index];

            if(count >= MAX_PHRASES)
                return SMCParse_Continue;

            strcopy(Phrases[index][count], sizeof(Phrases[][]), value);
            PhrasesCount[index]++;
        }
        case Section_Colors:
        {
            int index = SMC_GetColor(key);
            if(index != -1)
            {
                strcopy(Colors[index], sizeof(Colors[]), value);
            }
        }
        case Section_Beacon: BeaconOnKeyValue(key, value);
        case Section_Radio: RadioOnKeyValue(key, value);
        case Section_RadioColors: RadioColorsOnKeyValue(key, value);

        #if defined TRAIL
        case Section_Trail: TrailOnKeyValue(key, value);
        #endif
        
        #if defined NEON
        case Section_Neon: NeonOnKeyValue(key, value);
        #endif

        #if defined MARKERS
        case Section_Markers: MarkersOnKeyValue(key, value);
        #endif

        #if defined MUTE
        case Section_Mute: MuteOnKeyValue(key, value);
        #endif
    }
    return SMCParse_Continue;
}

public SMCResult SMC_EndSection(SMCParser smc)
{
    switch(CurrentSection)
    {
        case Section_Colors:
        {
            for(int i = 0; i < COLORS_TOTAL; i++)
            {
                if(i != COLOR_DEFAULT && !Colors[i][0])
                    strcopy(Colors[i], sizeof(Colors[]), Colors[COLOR_DEFAULT]);
            }

            RadioColorsOnEndSection();
        }
        case Section_RadioColors:
        {
            if(SectionLoaded[Section_Colors])
                RadioColorsOnEndSection();
        }
    }
    SectionLoaded[CurrentSection] = true;

    return SMCParse_Continue;
}

static int SMC_GetSection(const char[] name)
{
    for(int i = 0; i < Section_Total; i++)
    {
        if(!strcmp(name, Sections[i], false))
        {
            return i;
        }
    }
    return Section_None;
}

static int SMC_GetColor(const char[] name)
{
    for(int i = 0; i < sizeof(ColorsKeys); i++)
    {
        if(!strcmp(name, ColorsKeys[i], false))
            return i;
    }

    return -1;
}

static int SMC_GetAction(const char[] key)
{
    for(int i = 0; i < sizeof(ActionsKeys); i++)
    {
        if(!strcmp(ActionsKeys[i], key, false))
            return i;
    }

    return -1;
}