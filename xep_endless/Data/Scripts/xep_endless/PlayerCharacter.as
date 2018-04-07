array<PlayerCharacter@> players;

class PlayerCharacter : Character {
    void update() {
        if (timeOfDeath == 0)
        {
            Character::update();
            if (timeOfDeath != 0)
            {
                PlaySoundGroup("Data/Sounds/versus/fight_lose2.xml");
            }
        } else {
            Character::update();
        }
    }
}