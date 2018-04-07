array<RunnerHidingSpot@> runnerHidingSpots;

class RunnerHidingSpot {
    Object@ object;

    void initialize(Object@ obj)
    {
        @object = obj;
    }

    vec3 getPosition()
    {
        return object.GetTranslation();
    }
}

void RefreshHidingSpots()
{
    array<RunnerHidingSpot@> new_runnerHidingSpots;
    //Find all of the hiding spots
    uint numHotspots = GetNumHotspots();
    for (uint i = 0; i < numHotspots; ++i)
    {
        Hotspot@ hotspot = ReadHotspot(i);
        int id = hotspot.GetID();
        Object@ object = ReadObjectFromID(id);
        ScriptParams@ params = object.GetScriptParams();
        if (params.HasParam("Name")) {
            if(params.GetString("Name") == "runner_hiding_spot" ) {
                RunnerHidingSpot pp;
                pp.initialize(object);
                new_runnerHidingSpots.insertLast(@pp);
            }
        }
    }

    runnerHidingSpots = new_runnerHidingSpots;
}