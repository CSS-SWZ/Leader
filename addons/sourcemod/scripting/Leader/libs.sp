#if defined _sourcebanspp_included
bool sourcebanspp;
#endif

void LibsInit()
{
    #if defined _sourcebanspp_included
    sourcebanspp = LibraryExists("sourcebans++");
    #endif
}

void LibsManage(const char[] name, bool added)
{
    #if defined _sourcebanspp_included
    if(!strcmp(name, "sourcebans++", false))
    {
        sourcebanspp = added;
        return;
    }
    #endif
}