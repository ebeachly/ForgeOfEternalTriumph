

class MusicPlayer {
	private int stingHandle = -1;
	private float musicStingEnd = 0;
	private int currentMusicLayer = 0;
	private string musicPrefix = "";
	private string successSting = "";
	private string defeatSting = "";
	private bool slaversMusicAdded = false;
	private bool swampMusicAdded = false;
	private bool catsMusicAdded = false;
	private bool creteMusicAdded = false;
	private bool rescueMusicAdded = false;
	private bool arenaMusicAdded = false;

	void setMusic(string musicName) {
		if(musicName == "slaver"){
			if (!slaversMusicAdded)
			{
				AddMusic("Data/Music/slaver_loop/layers.xml");
				slaversMusicAdded = true;
			}
			PlaySong("slavers1");
			musicPrefix = "slavers_";
			successSting = "Data/Music/slaver_loop/the_slavers_success.wav";
			defeatSting = "Data/Music/slaver_loop/the_slavers_defeat.wav";

		} else if(musicName == "swamp"){
			if (!swampMusicAdded)
			{
				AddMusic("Data/Music/swamp_loop/swamp_layer.xml");
				swampMusicAdded = true;
			}
			PlaySong("swamp1");
			musicPrefix = "swamp_";
			successSting = "Data/Music/swamp_loop/swamp_success.wav";
			defeatSting = "Data/Music/swamp_loop/swamp_defeat.wav";

		} else if(musicName == "cats"){
			if (!catsMusicAdded)
			{
				AddMusic("Data/Music/cats_loop/layers.xml");
				catsMusicAdded = true;
			}
			PlaySong("cats1");
			musicPrefix = "cats_";
			successSting = "Data/Music/cats_loop/cats_success.wav";
			defeatSting = "Data/Music/cats_loop/cats_defeat.wav";

		} else if(musicName == "crete"){
			if (!creteMusicAdded)
			{
				AddMusic("Data/Music/crete_loop/layers.xml");
				creteMusicAdded = true;
			}
			PlaySong("crete1");
			musicPrefix = "crete_";
			successSting = "Data/Music/crete_loop/crete_success.wav";
			defeatSting = "Data/Music/crete_loop/crete_defeat.wav";

		} else if(musicName == "rescue"){
			if (!rescueMusicAdded){
				AddMusic("Data/Music/rescue_loop/layers.xml");
				rescueMusicAdded = true;
			}
			PlaySong("rescue1");
			musicPrefix = "rescue_";
			successSting = "Data/Music/rescue_loop/rescue_success.wav";
			defeatSting = "Data/Music/rescue_loop/rescue_defeat.wav";
			
		} else if(musicName == "arena"){
			if (!arenaMusicAdded)
			{
				AddMusic("Data/Music/SubArena/layers.xml");
				arenaMusicAdded = true;
			}
			PlaySong("sub_arena");
			musicPrefix = "arena_";
			successSting = "Data/Sounds/versus/fight_win1_1.wav";
			defeatSting = "Data/Sounds/versus/fight_lose1_1.wav";
		} else {
			
		}
	}

	void playSuccessSting() {
		if(stingHandle != -1){
			StopSound(stingHandle);
			stingHandle = -1;
		}
		stingHandle = PlaySound(successSting);
		SetSoundGain(stingHandle, GetConfigValueFloat("music_volume"));
		musicStingEnd = the_time + 5.0;
		SetLayerGain(musicPrefix+"layer_"+currentMusicLayer, 0.0);
	}

	void playDeathSting() {
		if(stingHandle != -1){
			StopSound(stingHandle);
			stingHandle = -1;
		}
		stingHandle = PlaySound(defeatSting);
		SetSoundGain(stingHandle, GetConfigValueFloat("music_volume"));
		musicStingEnd = the_time + 5.0;
		SetLayerGain(musicPrefix+"layer_"+currentMusicLayer, 0.0);    
	}

	void update() {
		if(the_time >= musicStingEnd ){
			if(musicStingEnd != 0.0){
				musicStingEnd = 0.0;
				SetLayerGain(musicPrefix+"layer_"+currentMusicLayer, 1.0);
			}
		} else {
			SetLayerGain(musicPrefix+"layer_"+currentMusicLayer, 0.0);
		}
	}

	void setMusicLayer(int layer){
		if(layer != currentMusicLayer){
			for(int i=0; i<5; ++i){
		    	SetLayerGain(musicPrefix+"layer_"+i, 0.0);
			}
			if (layer >= 0 && layer <= 5)
			{
				SetLayerGain(musicPrefix+"layer_"+layer, 1.0);
			}
			currentMusicLayer = layer;
		}
	}
}