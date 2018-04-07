array<CharacterSpawn@> characterSpawns;

class CharacterSpawn {
    Object@ object;

    float timeLastUsed = 0;

    float timeSinceLastUsed(float currentTime)
    {
        return currentTime - timeLastUsed;
    }

    void initialize(Object@ obj)
    {
        @object = obj;
    }

    vec3 getPosition()
    {
        return object.GetTranslation();
    }

    quaternion getRotation()
    {
    	return object.GetRotation();
    }
}

void RefreshSpawnPoints()
{
    array<CharacterSpawn@> new_characterSpawns;
    array<int> placeholderObjectIds = GetObjectIDsType(_placeholder_object);
    for (uint i = 0; i < placeholderObjectIds.length; ++i)
    {
        Object@ object = ReadObjectFromID(placeholderObjectIds[i]);
        ScriptParams@ params = object.GetScriptParams();
        if (params.HasParam("Name")) {
            if(params.GetString("Name") == "character_spawn" ) {
                CharacterSpawn cs;
                cs.initialize(object);
                new_characterSpawns.insertLast(@cs);
            }
        }
    }
    characterSpawns = new_characterSpawns;
}