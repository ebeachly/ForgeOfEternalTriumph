//~ To PAUSE Editor
#include "xep_endless\Character.as"
#include "xep_endless\RunnerHidingSpot.as"
#include "xep_endless\CharacterSpawn.as"
#include "xep_endless\MusicPlayer.as"

void SetParameters() {
    params.AddString("Music", "rescue");
    params.AddInt("Difficulty 1 Number of NPCs", 3);
    params.AddInt("Difficulty 1 Runner % Chance", 5);
    params.AddInt("Score to Unlock Difficulty 2", 3);
    params.AddInt("Difficulty 2 Number of NPCs", 4);
    params.AddInt("Difficulty 2 Runner % Chance", 10);
    params.AddInt("Score to Unlock Difficulty 3", 10);
    params.AddInt("Difficulty 3 Number of NPCs", 5);
    params.AddInt("Difficulty 3 Runner % Chance", 20);
}

void RefreshObjects()
{
    RefreshCharacters();
    RefreshHidingSpots();
    RefreshSpawnPoints();
    //Set the music
    mp.setMusic(params.GetString("Music"));
}

MusicPlayer mp;
void Reset() {
    RefreshObjects();
    for (uint i = 0; i < npcs.length(); i++) {
        npcs[i].kill();
    }
}

int textDisplayCounter = -1;
void DisplayText(string textToDisplay, int ticks)
{
    level.SendMessage("displaytext \""+ textToDisplay +"\"");
    textDisplayCounter = ticks;
}

int TextInit(int width, int height){
    int id = level.CreateTextElement();
    TextCanvasTexture @text = level.GetTextElement(id);
    text.Create(width, height);
    return id;
}

int ingame_text_id;
uint char_limit = 256;
void UpdateIngameText(string str) {
    TextCanvasTexture @text = level.GetTextElement(ingame_text_id);
    text.ClearTextCanvas();
    string font_str = "Data/UI/arena/images/arabtype.ttf";
    TextStyle style;
    style.font_face_id = GetFontFaceID(font_str, 128);

    vec2 pen_pos = vec2(0,100);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(255,255,255,255);
    text.SetPenRotation(0.0f);

    text.AddText(str, style, char_limit);

    text.UploadTextCanvasToTexture();
}

uint maxNumLivingNpcs;
float percentChanceOfRunner;
void tryToSpawnNpc() {
    float currentTime = the_time;
    array<int> deadNpcs;
    array<int> livingNpcs;
    for (uint i = 0; i < npcs.length; ++i)
    {
        if (npcs[i].timeSinceDeath(currentTime) > 5)
        {
            deadNpcs.insertLast(i);
        } else if (!npcs[i].isKnockedOut()) {
            livingNpcs.insertLast(i);
        }
    }

    //Check if there's room to spawn another npc
    if (livingNpcs.length < maxNumLivingNpcs) {
        //Figure out which npcs are best to spawn
        array<int> goodNpcsToSpawn;
        //If we didn't find any candidates
        if (goodNpcsToSpawn.length == 0) {
            //Add all the npcs
            for (uint i = 0; i < deadNpcs.length; ++i)
            {
                //Check that the npc is easier or equal to the current difficulty level
                if (npcs[deadNpcs[i]].getDifficulty() <= currentDifficulty)
                {
                    goodNpcsToSpawn.insertLast(deadNpcs[i]);
                }
            }
        }
        array<CharacterSpawn@> goodSpawns; 
        //Find a spawn point
        for (uint i = 0; i < characterSpawns.length; ++i)
        {
            //Don't use a recently used spawn point
            if (characterSpawns[i].timeSinceLastUsed(currentTime) > 10) {
                goodSpawns.insertLast(characterSpawns[i]);
            }
        }
        if (goodNpcsToSpawn.length > 0 && goodSpawns.length > 0)
        {
            //Randomly pick a good npc to spawn
            int luckyBastardIndex = rand()%(goodNpcsToSpawn.length);
            //Randomly pick a spawn point
            int spawnPointIndex = rand()%(goodSpawns.length);
            npcs[goodNpcsToSpawn[luckyBastardIndex]].respawn(goodSpawns[spawnPointIndex]);
            //DisplayText(livingNpcs.length + "/" +  maxNumLivingNpcs + " Spawing npc " + npcs[goodNpcsToSpawn[luckyBastardIndex]].id, 200);
            //Make this character notice all other characters
            for (uint i = 0; i < characters.length; ++i)
            {
                npcs[goodNpcsToSpawn[luckyBastardIndex]].notice(characters[i]);
            }
            //Check if we already have a runner
            for (uint i = 0; i < npcs.length; ++i)
            {
                if (npcs[i].isRunner)
                {
                    return;
                }
            }
            //Should this npc be a runner?
            if (rand() % 100 < percentChanceOfRunner)
            {
                //Do we have enough path points?
                if (runnerHidingSpots.length > 2)
                {
                    //Check that this npc is a valid runner
                    //Is it of the lowest difficulty?
                    if (npcs[goodNpcsToSpawn[luckyBastardIndex]].getDifficulty() <= 1) {
                        //Does it have an enemy player?
                        bool hasEnemyPlayer = false;
                        for (uint p = 0; p < players.length; ++p)
                        {
                            if (!npcs[goodNpcsToSpawn[luckyBastardIndex]].onSameTeam(players[p]))
                            {
                                hasEnemyPlayer = true;
                            }
                        }
                        if (hasEnemyPlayer)
                        {
                            DisplayText("Kill the runner to restore your health!", 500);
                            npcs[goodNpcsToSpawn[luckyBastardIndex]].isRunner = true;
                            npcs[goodNpcsToSpawn[luckyBastardIndex]].healsKiller = true;
                            npcs[goodNpcsToSpawn[luckyBastardIndex]].sparkles = true;
                        }
                    }
                }
            }
        }
    }
}

bool previouslyInEditor = false;
bool initialized = false;
int currentDifficulty = 1;
bool reached50 = false;
bool ascended = false;
void Update() {
    if (!initialized)
    {
        //Create text canvas
        ingame_text_id = TextInit(512,512);
        Reset();
        initialized = true;
    }
    if (textDisplayCounter >= 0)
    {
        if (textDisplayCounter == 0 ) {
            level.SendMessage("cleartext");
        }
        --textDisplayCounter;
    }
    if (inEditor)
    {
        RefreshObjects();
    }
    mp.update();
    int highestCurrentScore = 0;
    for (uint i = 0; i < players.length(); ++i)
    {
        players[i].update();
        //Check if the player has been dead for at least 1 second
        if (players[i].timeSinceDeath(the_time) > 1.0) {
            //Check if they want to respawn
            if(GetInputPressed(i, "attack")){
                if (characterSpawns.length > 0)
                {
                    float longestTime = 0;
                    uint bestSpawn = 0;
                    //Find the least recently used spawn point
                    for (uint s = 0; s < characterSpawns.length; ++s)
                    {
                        //Don't use a recently used spawn point
                        if (characterSpawns[s].timeSinceLastUsed(the_time) > longestTime) {
                            longestTime = characterSpawns[s].timeSinceLastUsed(the_time);
                            bestSpawn = s;
                        }
                    }
                    players[i].respawn(characterSpawns[bestSpawn]);
                } else {
                    DisplayText("You must have at least 1 Character Spawn Point", 400);
                }
            }
        }
        if (players[i].currentScore > highestCurrentScore)
        {
            highestCurrentScore = players[i].currentScore;
        }
    }

    for (uint i = 0; i < npcs.length(); ++i)
    {
        npcs[i].update();
    }

    //Figure out the difficulty level
    if (highestCurrentScore >= params.GetInt("Score to Unlock Difficulty 3") )
    {
        currentDifficulty = 3;
        maxNumLivingNpcs = params.GetInt("Difficulty 3 Number of NPCs");
        percentChanceOfRunner = params.GetInt("Difficulty 3 Runner % Chance");
        //Check for godhood
        if (highestCurrentScore >= 10 * params.GetInt("Score to Unlock Difficulty 3")) {
        	if (!ascended) {
        		DisplayText("Congratulations", 400);
	        	mp.setMusicLayer(0);
	        	mp.playSuccessSting();
	        	ascended = true;
	        }
	        //All the npcs are terrified of you
            for (uint i = 0; i < npcs.length; ++i) {
                npcs[i].isRunner = true;
            }
        } else {
        	mp.setMusicLayer(4);
        }
    } else if (highestCurrentScore >= params.GetInt("Score to Unlock Difficulty 2") ){
        currentDifficulty = 2;
        ascended = false;
        maxNumLivingNpcs = params.GetInt("Difficulty 2 Number of NPCs");
        percentChanceOfRunner = params.GetInt("Difficulty 2 Runner % Chance");
        mp.setMusicLayer(3);
    } else {
        currentDifficulty = 1;
        ascended = false;
        maxNumLivingNpcs = params.GetInt("Difficulty 1 Number of NPCs");
        percentChanceOfRunner = params.GetInt("Difficulty 1 Runner % Chance");
        
        if (highestCurrentScore == 0)
        {
            //Check if any players have attacked an enemy in this life
            bool inCombat = false;
            for (uint i = 0; i < players.length(); ++i)
            {
                if (players[i].lastTimeAttacking != 0)
                {
                    inCombat = true;
                    break;
                }
            }
            if (inCombat)
            {
                mp.setMusicLayer(2);
            } else {
                mp.setMusicLayer(1);
            }
        }
    }

    

    tryToSpawnNpc();
}


bool inEditor = true;
int drawCounter;
void PreDraw(float curr_game_time) {
    drawCounter = 0;
}

void DrawEditor() {
    inEditor = true;
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    DebugDrawBillboard("Data/UI/xep_endless/thumbs/infinity.png",
                       obj.GetTranslation(),
                       obj.GetScale()[1]*2.0,
                       vec4(vec3(0.5), 1.0),
                       _delete_on_draw);
}

void Draw() {
    if (!inEditor)
    {
        UpdateIngameText(players[drawCounter].currentScore + "/" + players[drawCounter].maxScore);
        HUDImage @image = hud.AddImage();
        image.SetImageFromText(level.GetTextElement(ingame_text_id));
        image.position.x = 20;//GetScreenWidth()/2-256;
        image.position.z = 3;
        image.color = vec4(1,1,1,1);
        if (players.length == 1)
        {
        	image.position.y = GetScreenHeight()-500;
            image.scale = vec3(1,1,1);
        } else if (players.length == 2){
            image.position.y = GetScreenHeight()/2-500;
            image.scale = vec3(1,2,1);
        } else if (players.length >= 3) {
        	image.position.y = GetScreenHeight()/2-500;
            image.scale = vec3(2,2,1);
        }
    } else {
        inEditor = false;
    }
    ++drawCounter;
}