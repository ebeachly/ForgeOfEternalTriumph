array<PlayerCharacter@> players;

class PlayerCharacter : Character {
    void update() {
        if (!dead)
        {
            Character::update();
            if (dead)
            {
                PlaySoundGroup("Data/Sounds/versus/fight_lose2.xml");
            }
        } else {
            Character::update();
        }
    }

    int getScoreValue() {
        if (currentScore < difficulty2ScoreThreshold) {
            return 1;
        } else if (currentScore < difficulty3ScoreThreshold) {
            return 2;
        } else {
            return 3;
        }
    }
}