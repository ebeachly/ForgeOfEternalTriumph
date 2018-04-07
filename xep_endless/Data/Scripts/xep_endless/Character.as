#include "xep_endless\PlayerCharacter.as"
#include "xep_endless\NonPlayerCharacter.as"

const int movementState = 0; // character is moving on the ground
const int groundState = 1; // character has fallen down or is raising up, ATM ragdolls handle most of this
const int attackState = 2; // character is performing an attack
const int hitReactionState = 3; // character was hit or dealt damage to and has to react to it in some manner
const int ragdollState = 4; // character is falling in ragdoll mode

array<Character@> characters;

class Character {
    int id;
    bool healsKiller = false;
    bool sparkles = false;
    int sparklePeriodCounter = 0;

    array<int> startingWeaponIds;
    //startingWeaponIds[0] = held left
    //startingWeaponIds[1] = held right
    //startingWeaponIds[2] = sheathed left
    //startingWeaponIds[3] = sheathed right
    //startingWeaponIds[4] = sheathed left sheath
    //startingWeaponIds[5] = sheathed right sheath
    //-1 if nothing is in that slot

    MovementObject@ mo;
    Object@ obj;
    ScriptParams@ params;

    void initialize(int id) {
        this.id = id;
        @mo = ReadCharacterID(id);
        for (int i = 0; i < 6; ++i)
        {
            int weaponId = mo.GetArrayIntVar("weapon_slots", i);
            startingWeaponIds.insertLast(weaponId);
        }
        @obj = ReadObjectFromID(id);
        @params = obj.GetScriptParams();
        if( !params.HasParam("_ Endless Difficulty") ) {
            params.AddInt("_ Endless Difficulty", 1);
        }
    }

    int getDifficulty()
    {
        return params.GetInt("_ Endless Difficulty");
    }

    int getScoreValue() {
        return 1;
    }

    bool isCarryingWeapon(int weaponId) {
        for (int i = 0; i < 6; ++i)
        {
            if (mo.GetArrayIntVar("weapon_slots", i) == weaponId)
            {
                return true;
            }
        }
        return false;
    }

    bool isKnockedOut() {
        return mo.GetIntVar("knocked_out") != _awake;
    }

    int deaths = 0;
    int cumulativeKills = 0;
    int cumulativeScore = 0;
    int currentScore = 0;
    int maxScore = 0;
    void scoredKill(int idOfVictim, int points) {
        currentScore += points;
        cumulativeScore += points;
        cumulativeKills += 1;
        if (currentScore > maxScore)
        {
            maxScore = currentScore;
        }
    }

    bool dead = false;
    float timeOfDeath = 0;
    float lastTimeAttackState = 0;

    float getLastTimeAttacking() {
        float lastKnifeTime = mo.GetFloatVar("last_knife_time");
        //Convert to our time
        lastKnifeTime = (lastKnifeTime - mo.GetFloatVar("time")) + the_time;
        if (lastKnifeTime > lastTimeAttackState) {
            return lastKnifeTime;
        } else {
            return lastTimeAttackState;
        }
    }
    
    int lastCharacterToDamage = -1;

    protected float lastPermanentHealth = 1.0f;
    protected float lastBloodHealth = 1.0f;
    void update() {
        //If this player is not already considered dead
        if (!dead)
        {
            //What is their health?
            float currentPermanentHealth = getPermanentHealth();
            float currentBloodHealth = getBloodHealth();
            //Check if damage was taken
            if ((currentPermanentHealth < lastPermanentHealth) || (currentBloodHealth < lastBloodHealth) || beingExecuted()) {
                //Who was the last person to attack this character?
                int attacker = mo.GetIntVar("attacked_by_id");
                //Clear the flag so we can distinguish attacks
                mo.Execute("attacked_by_id = -1;");
                //Who is this character?
                bool found = false;
                for (uint i = 0; i < characters.length && !found; ++i)
                {
                    if (characters[i].id == attacker)
                    {
                        //Did this actually happen?
                        //Check when that character last attacked, and how far away they are
                        float timeSinceLastAttack = the_time - characters[i].getLastTimeAttacking();
                        float distanceBetweenCombatants = distance(characters[i].getPosition(), getPosition());
                        if ((timeSinceLastAttack < 0.5) && (distanceBetweenCombatants < 3) || beingExecuted())
                        {
                            lastCharacterToDamage = attacker;
                        } else {
                            //Maybe this character was damaged by the environment after "attacker" performed a non-damaging attack
                            //Don't credit attacker with this damage

                            //TODO: Consider possibility of thrown weapon here
                            //Or not, throwing is cheesy af
                        }
                        found = true;
                    }
                }
            }
            lastPermanentHealth = currentPermanentHealth;
            lastBloodHealth = currentBloodHealth;

            //Check if they should sparkle
            if (sparkles) {
                if (sparklePeriodCounter == 0)
                {
                    uint32 id = MakeParticle("Data/Particles/metalspark.xml",
                                                getPosition() + vec3(RangedRandomFloat(-0.25f, 0.25f), RangedRandomFloat(-0.5f, 0.5f), RangedRandomFloat(-0.25f, 0.25f)),
                                                vec3(0, 0, 0),
                                                vec3(2.0f));
                    sparklePeriodCounter = 10;
                } else {
                    sparklePeriodCounter--;
                }
            }
        }

        if (isKnockedOut())
        {
            if (!dead)
            {
                //Who was the last person to damage this character?
                int killer = lastCharacterToDamage;
                //Who is this character?
                bool found = false;
                for (uint i = 0; i < players.length && !found; ++i)
                {
                    if (players[i].id == killer)
                    {
                        found = true;
                        //Attribute the kill to this player
                        players[i].scoredKill(id, getScoreValue());
                        if (healsKiller)
                        {
                            players[i].fullyHeal();
                            //Play a special sound
                            PlaySoundGroup("Data/Sounds/versus/fight_win2.xml");
                            DisplayText("Runner killed! Health restored.", 200);
                        } else {
                            //Play a sound
                            PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");
                        }
                    }
                }
                for (uint i = 0; i < npcs.length && !found; ++i)
                {
                    if (npcs[i].id == killer)
                    {
                        found = true;
                        //Attribute the kill to this npc
                        npcs[i].scoredKill(id, getScoreValue());
                    }
                }
                sparkles = false;
                deaths += 1;
                currentScore = 0;
                timeOfDeath = the_time;
                dead = true;
                lastCharacterToDamage = -1;
            }
            lastTimeAttackState = 0;
        } else {
            if (getState() == attackState) {
                lastTimeAttackState = the_time;
            }
        }
    }

    float timeSinceDeath(float currentTime) {
        if (dead)
        {
            return currentTime - timeOfDeath;
        } else {
            return -1;
        }
    }

    vec3 getPosition() {
        return mo.rigged_object().GetAvgPosition();
    }

    void sendToUnderworld() {
        mo.ReceiveMessage("set_dialogue_control true");
        mo.ReceiveMessage("set_dialogue_position " + mo.position.x + " " + (mo.position.y - 3000) + " " + mo.position.z);
        mo.ReceiveMessage("set_dialogue_control false");
    }

    bool beingExecuted() {
        if (mo.GetIntVar("being_executed") != 0) {
            //DisplayText("Being Executed " + mo.GetIntVar("being_executed") + " " + mo.GetIntVar("attacked_by_id"), 200);
            return true;
        } else {
            return false;
        }
    }

    bool executing() {
        return mo.GetBoolVar("executing");
    }

    int getMaxKoShield() {
        return mo.GetIntVar("max_ko_shield");
    }

    void fullyHeal() {
        ReadCharacterID(id).ReceiveMessage("restore_health");
    }

    void respawn(CharacterSpawn@ spawnPoint) {
        spawnPoint.timeLastUsed = the_time;
        dead = false;
        //Need to preserve certain information
        int old_fire_object_id = mo.GetIntVar("fire_object_id");
        //Restore health
        mo.ReceiveMessage("full_revive");
        //Detach all of the items
        mo.Execute("DropWeapon(); Reset(); weapon_slots[0] = -1; weapon_slots[1] = -1; weapon_slots[2] = -1; weapon_slots[3] = -1; weapon_slots[4] = -1; weapon_slots[5] = -1;");
        //Revive the ragdoll so we can programmatically move it
        mo.ReceiveMessage("set_dialogue_control true");
        mo.ReceiveMessage("set_dialogue_control false");
        //Move to spawn point
        mo.position = spawnPoint.getPosition();
        mo.SetRotationFromFacing(spawnPoint.getRotation() * vec3(0,0,1));
        //Set velocity to zero. This doesn't really work though
        mo.velocity = vec3(0,0,0);
        //Verify each starting weapons still exist
        for (uint i = 0; i < 6; ++i)
        {
            if (!ObjectExists(startingWeaponIds[i])) {
                startingWeaponIds[i] = -1;
            }
        }
        //Attach starting items if they aren't already equipped by someone else
        if (startingWeaponIds[0] != -1 && !isAnyoneCarryingWeapon(startingWeaponIds[0]))
        {
            mo.Execute("this_mo.AttachItemToSlot( " + startingWeaponIds[0] + ", _at_grip, true); HandleEditorAttachment( " + startingWeaponIds[0] + ", _at_grip, true);");
        }
        if (startingWeaponIds[1] != -1 && !isAnyoneCarryingWeapon(startingWeaponIds[1]))
        {
            mo.Execute("this_mo.AttachItemToSlot( " + startingWeaponIds[1] + ", _at_grip, false); HandleEditorAttachment( " + startingWeaponIds[1] + ", _at_grip, false);");
        }
        if (startingWeaponIds[2] != -1 && !isAnyoneCarryingWeapon(startingWeaponIds[2]))
        {
            mo.Execute("this_mo.AttachItemToSlot( " + startingWeaponIds[2] + ", _at_sheathe, false); HandleEditorAttachment( " + startingWeaponIds[2] + ", _at_sheathe, false);");
        }
        if (startingWeaponIds[3] != -1 && !isAnyoneCarryingWeapon(startingWeaponIds[3]))
        {
            mo.Execute("this_mo.AttachItemToSlot( " + startingWeaponIds[3] + ", _at_sheathe, true); HandleEditorAttachment( " + startingWeaponIds[3] + ", _at_sheathe, true);");
        }
        if (startingWeaponIds[4] != -1 && !isAnyoneCarryingWeapon(startingWeaponIds[4]))
        {
            mo.Execute("this_mo.AttachItemToSlot( " + startingWeaponIds[4] + ", _at_sheathe, false); HandleEditorAttachment( " + startingWeaponIds[4] + ", _at_sheathe, false);");
        }
        if (startingWeaponIds[5] != -1 && !isAnyoneCarryingWeapon(startingWeaponIds[4]))
        {
            mo.Execute("this_mo.AttachItemToSlot( " + startingWeaponIds[5] + ", _at_sheathe, true); HandleEditorAttachment( " + startingWeaponIds[5] + ", _at_sheathe, true);");
        }
        healsKiller = false;
        sparkles = false;
        lastPermanentHealth = 1.0f;
        mo.Execute("SetCameraFromFacing(); SetOnGround(true); FixDiscontinuity();");

        //For some reason the game randomly crashes sometimes if you fall in lava because it tries to access fire_object_id. This code ensures the crash doesn't happen
        if (old_fire_object_id != -1)
        {
            int new_fire_object_id = mo.GetIntVar("fire_object_id");
            if (new_fire_object_id != old_fire_object_id)
            {
                if (new_fire_object_id == -1)
                {
                    mo.Execute("fire_object_id = CreateObject(\"Data/Objects/default_light.xml\", true);");
                }
            }
        }
    }

    void kill() {
        timeOfDeath = the_time;
        lastCharacterToDamage = -1;
        mo.Execute("TakeBloodDamage(100.0f);Ragdoll(_RGDL_FALL);zone_killed=1;");
    }

    int getState() {
        return mo.QueryIntFunction("int GetState()");
    }

    bool onSameTeam(Character other) {
        return mo.OnSameTeam(other.mo);
    }

    float getPermanentHealth() {
        return mo.GetFloatVar("permanent_health");
    }

    float getBloodHealth() {
        return mo.GetFloatVar("blood_health");
    }

    void notice(Character other) {
        mo.ReceiveMessage("notice "+other.id);
    }
}


bool isAnyoneCarryingWeapon(int id) {
    for (uint i = 0; i < characters.length; ++i)
    {
        if (characters[i].isCarryingWeapon(id)){
            return true;
        }
    }
    return false;
}


void RefreshCharacters()
{
    array<Character@> new_characters;
    array<PlayerCharacter@> new_players;
    array<NonPlayerCharacter@> new_npcs;

    //Get all of the characters
    array<int> id_array;
    GetCharacters(id_array);

    for (uint i = 0; i < id_array.length(); i++) {
        MovementObject@ movementObject =  ReadCharacterID(id_array[i]);
        //Check if this character is already being tracked
        bool found = false;
        for (uint j = 0; j < players.length; ++j)
        {
            if (@players[j].mo == @movementObject)
            {
                new_players.insertLast(players[j]);
                new_characters.insertLast(players[j]);
                found = true;
                break;
            }
        }
        if (!found)
        {
            for (uint j = 0; j < npcs.length; ++j)
            {
                if (@npcs[j].mo == @movementObject)
                {
                    new_npcs.insertLast(npcs[j]);
                    new_characters.insertLast(npcs[j]);
                    found = true;
                    break;
                }
            }
        }
        //If it's a new object
        if (!found)
        {
            //Is this a player-controlled character or not?
            if (movementObject.is_player)
            {
                PlayerCharacter pc;
                pc.initialize(id_array[i]);
                new_players.insertLast(@pc);
                new_characters.insertLast(@pc);
            } else {
                NonPlayerCharacter npc;
                npc.initialize(id_array[i]);
                new_npcs.insertLast(@npc);
                new_characters.insertLast(@npc);
            }
        }
    }

    //Set the new arrays
    characters = new_characters;
    players = new_players;
    npcs = new_npcs;
}