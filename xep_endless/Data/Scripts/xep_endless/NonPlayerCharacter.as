array<NonPlayerCharacter@> npcs;

class NonPlayerCharacter : Character {
    bool isRunner = false;
    uint hidingSpotIndex = 9000;
    vec3 lastPosition = vec3(0,-9000,0);
    float lastPositionTime = 0;
    void update() {
        Character::update();
        if (!dead)
        {
            //Has this character moved 3 meters from their previous position?
            if (distance_squared(getPosition(), lastPosition) >= 9) {
                lastPosition = getPosition();
                lastPositionTime = the_time;
            }
            //Is this character stuck?
            if (the_time - lastPositionTime > 60) {
                kill();
                return;
            }
            if (isRunner)
            {
                //Are there enough path points?
                if (runnerHidingSpots.length > 2)
                {
                    //How far away are we from an enemy player?
                    float distanceToClosestEnemyPlayer = 100;
                    for (uint p = 0; p < players.length; ++p)
                    {
                        if (!onSameTeam(players[p]))
                        {
                            float d = distance(players[p].getPosition(), getPosition());
                            if (d < distanceToClosestEnemyPlayer)
                            {
                                distanceToClosestEnemyPlayer = d;
                            }
                        }
                    }
                    if (distanceToClosestEnemyPlayer < 4)
                    {
                        //Our current destination is no good anymore
                        hidingSpotIndex = 9000;
                        //Stand and fight
                        stopRunning();
                    } else {
                        //Do we have a hiding spot?
                        if (hidingSpotIndex == 9000)
                        {
                            //Find one
                            findNewHidingSpot();
                        }
                        //Get the hiding spot position
                        vec3 hidingSpotPosition = runnerHidingSpots[hidingSpotIndex].getPosition();
                        runTo(hidingSpotPosition);
                        //Check how close we are to it
                        if (distance(hidingSpotPosition, getPosition()) < 4) {
                            //Find a new hiding spot
                            hidingSpotIndex = 9000;
                        }
                    }
                }
            }
        }
    }

    void respawn(CharacterSpawn@ spawnPoint) {
        Character::respawn(spawnPoint);
        isRunner = false;
    }

    void findNewHidingSpot() {
        //Calculate which path point has a higher combined distance from all living enemies
        float furthestDistance = 0;
        uint furthestPathPoint = 0;
        for (uint i = 0; i < runnerHidingSpots.length; ++i)
        {
            float d = 0;
            for (uint c = 0; c < characters.length; ++c)
            {
                if (!characters[c].isKnockedOut() && !onSameTeam(characters[c]))
                {
                    d += distance(characters[c].getPosition(), runnerHidingSpots[i].getPosition());
                }
            }
            if (d > furthestDistance)
            {
                furthestDistance = d;
                furthestPathPoint = i;
            }
        }
        hidingSpotIndex = furthestPathPoint;
    }

    void runTo(vec3 waypoint) {
        string command =    "nav_target = " + waypoint + ";" +
                            "goal = _navigate;";
        mo.Execute(command);
    }

    void stopRunning() {
        mo.Execute("if (goal == _navigate) {goal = _patrol;}");
    }

    bool aggroed() {
        if (mo.QueryIntFunction("int IsPassive()") == 0) {
            return false;
        } else {
            return true;
        }
    }

    int getScoreValue() {
        return getDifficulty();
    }
}