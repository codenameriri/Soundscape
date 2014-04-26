import themidibus.*;

/*
*	Instance Vars
*/

// Sketch props
int WIDTH = 400;
int HEIGHT = 400;
boolean playing;
char soundscape = '1';

// MidiBus + instruments
MidiBus mb;
int channel1, channel2, channel3, channel4, channel5, channel6;
RiriSequence kick, perc1, perc2, bass, synth1, synth2;

// Data + levels
int HISTORY_LENGTH = 8;
int BASE_LEVEL_STEP = 4;
int MAX_FOCUS = 100;
int MAX_RELAX = -100;
int MAX_BPM = 100;
int MIN_BPM = 50;
int pulse, bpm, grain;
int focusRelaxLevel, level;
IntList pulseHist, levelHist;

// Timekeeping
int BEATS_PER_MEASURE = 4;
int MEASURES_PER_PHASE = 8;
int PHASES_PER_SONG = 4;
int DELAY_THRESHOLD = 20;
int beat, measure, phase, mils, lastMils, delay;

// Music + scales
int PITCH_C = 60;
int PITCH_F = 65;
int PITCH_G = 67;
int[] SCALE = {0, 2, 4, 5, 7, 9};
float[] BEATS = {1, .5, .25, .125};
int pitch;

// Filters
int highPassFilterVal, lowPassFilterVal;

/*
*	Sketch Setup
*/

void setup() {
	// Sketch setup
	size(WIDTH, HEIGHT);
	background(0);
	frameRate(60);
	playing = false;
	// MidiBus setup
	MidiBus.list();
	mb = new MidiBus(this, -1, "Virtual MIDI Bus");
	mb.sendTimestamps();
	channel1 = 0;
	channel2 = 1;
	channel3 = 2;
	channel4 = 3;
	channel5 = 4;
	channel6 = 5;
	// Data setup
	pulse = 65;
	bpm = pulse;
	pulseHist = new IntList();
	focusRelaxLevel = 0;
	level = 0;
	levelHist = new IntList();
	grain = 0;
	// Time setup
	delay = 0;
	mils = millis();
	lastMils = mils;
	beat = 0; 
	measure = 0;
	phase = 1;
	// Filter setup
	highPassFilterVal = 0;
	lowPassFilterVal = 127;
}

/*
*	Draw Loop
*/

void draw() {
	background(0);
	if (playing) {
		// Music
		playMusic();
		// Filters
		RiriMessage highPassFilterMsg = new RiriMessage(176, 0, 102, highPassFilterVal);
    	highPassFilterMsg.send();
    	RiriMessage lowPassFilterMsg = new RiriMessage(176, 0, 103, lowPassFilterVal);
    	lowPassFilterMsg.send();
	}
	// DEBUG
	text("focusRelaxLevel: " + focusRelaxLevel, 0, 20);
	text("level: " + level, 0, 40);
	text("grain: " + grain, 0, 60);
	text("pulse: " + pulse, 0, 80);
	text("bpm: " + bpm, 0, 100);
	text("beat: " + beat, WIDTH/2, 20);
	text("measure: " + measure, WIDTH/2, 40);
	text("phase: " + phase, WIDTH/2, 60);
	text("highPass: "+highPassFilterVal, WIDTH/2, 100);
	text("lowPass: "+lowPassFilterVal, WIDTH/2, 120);
}

/*
*	Music Playing
*/

void setupMusic() {
	// Reset song position
	beat = 0;
	measure = 0;
	phase = 1;
	pitch = PITCH_C;
	// Setup the instruments
	createInstruments();
	createKickMeasure();
	createRestMeasure(perc1);
	createRestMeasure(perc2);
	createRestMeasure(bass);
	createRestMeasure(synth1);
	createRestMeasure(synth2);
	// Start all instruments
	startMusic();
}

void startMusic() {
	kick.start();
	perc1.start();
	perc2.start();
	bass.start();
	synth1.start();
	synth2.start();
}

void playMusic() {
	// Get current time
	mils = millis();
	// Beat Change
	if (mils > lastMils + beatsToMils(1)/1000 - delay) {
		int milsA = mils;
		//println("\tA: "+milsA);
		updateLevelHistory();
		updateBpmHistory();
		if (beat == BEATS_PER_MEASURE) {
			beat = 1;
			// Measure Change
			if (measure == MEASURES_PER_PHASE) {
				measure = 1;
				if (phase == PHASES_PER_SONG) {
					// We're done!
					stopMusic();
				}
				else {
					phase++;
				}
			}
			else if (measure == MEASURES_PER_PHASE - 1) {
				// Prepare for the next phase
				// createInstrumentsBeforePhase();
				setPhaseKey();
				measure++;
			}
			else {
				measure++;
			}
		}
		else if (beat == BEATS_PER_MEASURE - 1) {
			// Prepare the next measure
			setMeasureLevelAndGrain();
			setMeasureBPM();
			createMeasure();
			/*if (useDummyData) {
				String input = dummyDataGenerator.getInput("brainwave");
				calculateFocusRelaxLevel(input);
			}*/
			beat++;
		}
		else {
			beat++;
		}
		// Update the time
		lastMils = millis();
		int milsB = millis();
		//println("\tB: "+milsB);
		delay += milsB - milsA;
		println("DELAY: "+delay);
		if (delay > DELAY_THRESHOLD) delay = 0;
	}
}

void stopMusic() {
	// Stop all instruments
	kick.quit();
	perc1.quit();
	perc2.quit();
	bass.quit();
	synth1.quit();
	synth2.quit();
}

/*
*	Instruments
*/

void createInstruments() {
	kick = new RiriSequence(channel1);
	perc1 = new RiriSequence(channel2);
	perc2 = new RiriSequence(channel3);
	bass = new RiriSequence(channel4);
	synth1 = new RiriSequence(channel5);
	synth2 = new RiriSequence(channel6);
}

void createMeasure() {
	createKickMeasure();
	createPerc1Measure();
	createPerc2Measure();
	createBassMeasure();
	createSynth1Measure();
	createSynth2Measure();
}

void createRestMeasure(RiriSequence seq) {
	seq.addRest(beatsToMils(BEATS_PER_MEASURE));
}

void createKickMeasure() { // Bass drum
	// '2'
	if (soundscape == '2') {
		kick.addNote(36, 120, beatsToMils(.5));
		kick.addNote(36, 120, beatsToMils(.5));
		kick.addRest(beatsToMils(.5));
		kick.addNote(36, 120, beatsToMils(.5));
		kick.addRest(beatsToMils(.5));
		kick.addNote(36, 120, beatsToMils(.5));
		kick.addNote(36, 120, beatsToMils(.25));
		kick.addNote(36, 120, beatsToMils(.75));
	} 
	// '1' or default
	else {
		for (int i = 0; i < BEATS_PER_MEASURE; i++) {
			kick.addNote(36, 120, beatsToMils(1));
		}
	}
}

void createPerc1Measure() { // Hi-hat
	int close = 42;
	int open = 46;
	// '2'
	if (soundscape == '2') {
		createRestMeasure(perc1);
	}
	// '1' or default
	else {
		if (level >= 0) {
			if (grain == 0) {
				// Play a closed note every other measure
				for (int i = 0; i < BEATS_PER_MEASURE; i++) {
					if (i % 2 == 1) {
						perc1.addNote(close, 120, beatsToMils(1));
					}
					else {
						perc1.addRest(beatsToMils(1));
					}
				}
			}
			else if (grain == 1) {
				// Play a closed note every other measure
				for (int i = 0; i < BEATS_PER_MEASURE; i++) {
					if (i == BEATS_PER_MEASURE - 1) {
						perc1.addNote(close, 120, beatsToMils(.5));
						perc1.addNote(open, 120, beatsToMils(.5));
					}
					else {
						perc1.addNote(close, 120, beatsToMils(1));
					}
				}
			}
			else {
				for (int i = 0; i < BEATS_PER_MEASURE; i++) {
					if (i % 2 == 1) {
						perc1.addNote(close, 120, beatsToMils(.25));
						perc1.addNote(close, 80, beatsToMils(.25));
						perc1.addNote(close, 80, beatsToMils(.25));
						perc1.addNote(open, 120, beatsToMils(.25));
					}
					else {
						perc1.addNote(close, 120, beatsToMils(.25));
						perc1.addNote(close, 80, beatsToMils(.25));
						perc1.addNote(close, 80, beatsToMils(.25));
						perc1.addNote(close, 80, beatsToMils(.25));
					}
				}
			}
		}
		else {
			createRestMeasure(perc1);
		}
	}
}

void createPerc2Measure() { // Snare
	// '2'
	if (soundscape == '2') {
		createRestMeasure(perc2);
	}
	// '1' or default
	else {
		if (level >= 19) {
			if (grain == 0) {
				createRestMeasure(perc2);
			}
			else if (grain == 1) {
				for (int i = 0; i < BEATS_PER_MEASURE; i++) {
					if (i % 2 == 1) {
						perc2.addNote(38, 120, beatsToMils(1));
					}
					else {
						perc2.addRest(beatsToMils(1));
					}
				}
			}
			else if (grain == 2) {
				for (int i = 0; i < BEATS_PER_MEASURE*4; i++) {
					if (i == 4 || i == 7 || i == 12 || i == 15) {
						perc2.addNote(38, 120, beatsToMils(.25));
					}
					else {
						perc2.addRest(beatsToMils(.25));
					}
				}
			}
			else {
				for (int i = 0; i < BEATS_PER_MEASURE*4; i++) {
					if (i == 1 || i == 2 || i == 4 || i == 6 || i == 7 ||
						i == 9 || i == 10 || i == 12 || i == 14 || i == 15) {
						perc2.addNote(38, 120, beatsToMils(.25));
					}
					else {
						perc2.addRest(beatsToMils(.25));
					}
				}
			}
		}
		else {
			createRestMeasure(perc2);
		}
	}
}

void createBassMeasure() { // Bass
	// '2'
	if (soundscape == '2') {
		createRestMeasure(bass);
	}
	// '1' or default
	else {
		if (level >= -19) {
			int tmp = (grain - 1 >= 0) ? grain - 1 : 0;
			int interval = beatsToMils(BEATS[tmp]*2);
			// Random notes for now
			for (int i = 0; i < BEATS_PER_MEASURE / (BEATS[tmp] * 2); i++) {
				int p1 = pitch + SCALE[(int) random(0, SCALE.length)] - 24;
				bass.addNote(p1, 80, interval);
			}
		}
		else {
			createRestMeasure(bass);
		}
	}
	
}

void createSynth1Measure() { // Arp
	// '2'
	if (soundscape == '2') {
		createRestMeasure(synth1);
	}
	// '1' or default
	else {
		// If Relax is active, play the Arp
		if (level <= 0) {
			int interval = beatsToMils(BEATS[grain]);
			// Arp - Grain 0
			if (grain == 0) {
				// Random notes
				for (int i = 0; i < BEATS_PER_MEASURE; i++) {
					int p1 = pitch + SCALE[(int) random(0, SCALE.length)];
					synth1.addNote(p1, 80, interval);
				} 
			}

			// Arp - Grain 1 or higher
			else {
				int arpNotes[];
				int count = 0;
				if (grain == 1) {
					// Arpeggiate with I and V
					int[] tmp = {pitch, pitch + SCALE[3]};
					arpNotes = tmp;
				}
				else if (grain == 2) {
					// Arpeggiate with I, III, and V
					int [] tmp = {pitch, pitch + SCALE[2], pitch + SCALE[4], pitch + SCALE[2]};
					arpNotes = tmp;
				}
				else {
					// Arpeggiate with I, II, III, V, and VI
					int [] tmp = {pitch, pitch + SCALE[1], pitch + SCALE[2], pitch + SCALE[3], pitch + SCALE[4], pitch + SCALE[3], pitch + SCALE[2], pitch + SCALE[1]};
					arpNotes = tmp;
				}
				// RELIES ON 4/4 LOLOL
				int loops = 2;
				int howMany = (int) (BEATS_PER_MEASURE / BEATS[grain]);
				int octave = 0;
				//println(loops * howMany);
				for (int i = 0; i < howMany; i++) {
					synth1.addNote(arpNotes[count] + octave, 80, interval);
					if (count == arpNotes.length - 1) {
						count = 0;
						octave = (octave == 12) ? 0 : 12;
					}
					else {
						count++;
					}
				}
			}
		}
		// If not, rest
		else {
			createRestMeasure(synth1);
		}
	}
}

void createSynth2Measure() { // Pad
	// '2' 
	if (soundscape == '2') {
		createRestMeasure(synth2);
	}
	// '1' or default
	else {
		// If Relax is active, play the synth2
		if (level <= 19) {
			// Pad - Grain 0 and Grain 1
			if (grain <= 1) {
				int p1 = pitch - 12;
				int p2 = pitch + SCALE[(int) random(1, SCALE.length)] - 12;
				RiriChord c1 = new RiriChord(channel6);
				c1.addNote(p1, 80, beatsToMils(BEATS[0]*BEATS_PER_MEASURE));
				c1.addNote(p2, 80, beatsToMils(BEATS[0]*BEATS_PER_MEASURE));
				synth2.addChord(c1);
			}
			// Pad - Grain 2
			else if (grain == 2) {
				int p1 = pitch - 12;
				int p2 = pitch + SCALE[(int) random(1, SCALE.length)] - 12;
				RiriChord c1 = new RiriChord(channel6);
				c1.addNote(p1, 80, beatsToMils(BEATS[1]*BEATS_PER_MEASURE));
				c1.addNote(p2, 80, beatsToMils(BEATS[1]*BEATS_PER_MEASURE));
				p2 = pitch + SCALE[(int) random(1, SCALE.length)] - 12;
				RiriChord c2 = new RiriChord(channel6);
				c2.addNote(p1, 80, beatsToMils(BEATS[1]*BEATS_PER_MEASURE));
				c2.addNote(p2, 80, beatsToMils(BEATS[1]*BEATS_PER_MEASURE));
				synth2.addChord(c1);
				synth2.addChord(c2);
			}
			// Pad - Grain 3
			else {
				int p1 = pitch - 12;
				int p2 = pitch + SCALE[(int) random(1, SCALE.length)] - 12;
				RiriChord c1 = new RiriChord(channel6);
				c1.addNote(p1, 80, beatsToMils(BEATS[2]*BEATS_PER_MEASURE));
				c1.addNote(p2, 80, beatsToMils(BEATS[2]*BEATS_PER_MEASURE));
				p2 = pitch + SCALE[(int) random(1, SCALE.length)] - 12;
				RiriChord c2 = new RiriChord(channel6);
				c2.addNote(p1, 80, beatsToMils(BEATS[2]*BEATS_PER_MEASURE));
				c2.addNote(p2, 80, beatsToMils(BEATS[2]*BEATS_PER_MEASURE));
				p2 = pitch + SCALE[(int) random(1, SCALE.length)] - 12;
				RiriChord c3 = new RiriChord(channel6);
				c3.addNote(p1, 80, beatsToMils(BEATS[2]*BEATS_PER_MEASURE));
				c3.addNote(p2, 80, beatsToMils(BEATS[2]*BEATS_PER_MEASURE));
				p2 = pitch + SCALE[(int) random(1, SCALE.length)] - 12;
				RiriChord c4 = new RiriChord(channel6);
				c4.addNote(p1, 80, beatsToMils(BEATS[2]*BEATS_PER_MEASURE));
				c4.addNote(p2, 80, beatsToMils(BEATS[2]*BEATS_PER_MEASURE));
				synth2.addChord(c1);
				synth2.addChord(c2);
				synth2.addChord(c3);
				synth2.addChord(c4);
			}
		}
		// If not, rest
		else {
			createRestMeasure(synth2);
		}
	}
}

/*
*	Keyboard Input
*/
void keyPressed() {
	// Play/stop
	if (key == ' ') {
		playing = !playing;
		if (playing) setupMusic();
		else stopMusic();
	}
	// Focus/relax
	if (keyCode == LEFT) {
		addRelax();
	}
	if (keyCode == RIGHT) {
		addFocus();
	}
	// Pulse
	if (keyCode == UP) {
		pulse += 3;
	}
	if (keyCode == DOWN) {
		pulse -= 3;
	}
	// Filters
	if (key == 'q') {
		highPassFilterVal += 5;
		if (highPassFilterVal > 127) highPassFilterVal = 127;
	}
	if (key == 'a') {
		highPassFilterVal -= 5;
		if (highPassFilterVal < 0) highPassFilterVal = 0;
	}
	if (key == 'w') {
		lowPassFilterVal += 5;
		if (lowPassFilterVal > 127) lowPassFilterVal = 127;
	}
	if (key == 's') {
		lowPassFilterVal -= 5;
		if (lowPassFilterVal < 0) lowPassFilterVal = 0;
	}
	// Filter setup
	if (key == 'z') {
		RiriMessage msg = new RiriMessage(176, 0, 102, 0);
    	msg.send();
	}
	if (key == 'x') {
		RiriMessage msg = new RiriMessage(176, 0, 103, 127);
    	msg.send();
	}
	// Soundscape switching
	if (key == '1' || key == '2') {
		soundscape = key;
	}
	// DEBUG
	if (key == '0') {
		println("1/4: "+beatsToMils(1));
		println("1/8: "+beatsToMils(.5));
		println("1/16: "+beatsToMils(.25));
		println("1/32: "+beatsToMils(.125));
	}
}

/*
*	Utilities
*/

int beatsToMils(float BEATS){
  // (one second split into single BEATS) * # needed
  float convertedNumber = (60000000 / bpm) * BEATS;
  return round(convertedNumber);
}

float grainToBeat() {
	return BEATS[grain];
}

float grainToMils() {
	return beatsToMils(grainToBeat());
}

void addFocus() {
	focusRelaxLevel += (BASE_LEVEL_STEP - grain);
	if (focusRelaxLevel > MAX_FOCUS) focusRelaxLevel = MAX_FOCUS;
}

void addRelax() {
	focusRelaxLevel -= (BASE_LEVEL_STEP - grain);
	if (focusRelaxLevel < MAX_RELAX) focusRelaxLevel = MAX_RELAX;
}

void updateLevelHistory() {
	if (levelHist.size() == 4) {
		levelHist.remove(0);
	}
	levelHist.append(focusRelaxLevel);
}

void updateBpmHistory() {
	if (pulseHist.size() == 4) {
		pulseHist.remove(0);
	}
	pulseHist.append(pulse);
}

void setMeasureBPM() {
	// Get the average BPM
	float val = 0; 
	for (int i = 0; i < pulseHist.size(); i++) {
		val += pulseHist.get(i);
	}
	val = val/pulseHist.size();
	bpm = (int) val;
}

void setMeasureLevelAndGrain() {
	// Get the average focusRelaxLevel
	float val = 0;
	for (int i = 0; i < levelHist.size(); i++) {
		val += levelHist.get(i);
	}
	val = val/levelHist.size();
	// Set level
	level = (int) val;
	// Set grain
	val = abs(val);
	if (val < 20) {
		grain = 0;
	}
	else if (val >= 20 && val < 50) {
		grain = 1;
	}
	else if (val >= 50 && val < 80) {
		grain = 2;
	}
	else if (val >= 80) {
		grain = 3;
	}
	else {
		grain = 0; // Iunno
	}
}

void setPhaseKey() {
	int p = phase + 1;
	if (p == PHASES_PER_SONG - 2) {
		pitch = PITCH_F;
	}
	else if (p == PHASES_PER_SONG - 1) {
		pitch = PITCH_G;
	}
	else {
		pitch = PITCH_C;
	}
}