import processing.video.*;
import ddf.minim.*;

// this is the number of pixels that have to change for a picture to be taken.
// making this higer makes it less sensitive (fewer pictures).
int MOVEMENT_THRESHOLD = 100000;

// this is the minimum amount of time between each triggering (in milliseconds).
// 1000 = 1 second
int CAPTURE_PERIOD = 1000;

// to avoid taking pictures of empty frames, this is the number of pixels 
//   that have to differ between the current frame and the calibration background.
int BACKGROUND_THRESHOLD = 200000;

// this is the audio file to play when movement is detected
String AUDIO_FILENAME = "audio0.mp3";

long lastCaptureMillis;
int numPixels;
boolean showBackgroundDiff;
boolean needToCaptureBackground;
Capture video;
PImage mBackground, backDiff, frameDiff, previousFrame;

Minim mMinim;
AudioPlayer mAudioPlayer;

void setup() {
  size(640, 480);
  frameRate(30);

  video = new Capture(this, width, height);
  video.start(); 

  numPixels = video.width * video.height;

  lastCaptureMillis = millis();
  showBackgroundDiff = false;
  needToCaptureBackground = true;
  mBackground = createImage(width, height, ARGB);
  backDiff = createImage(width, height, ARGB);
  frameDiff = createImage(width, height, ARGB);
  previousFrame = createImage(width, height, ARGB);

  mMinim = new Minim(this);  
  mAudioPlayer = mMinim.loadFile(dataPath(AUDIO_FILENAME));
  mAudioPlayer.play(mAudioPlayer.length());
}

void draw() {
  if (video.available()) {
    video.read();
    video.loadPixels();

    if (needToCaptureBackground) {
      image(video, 0, 0);
      textSize(32);
      fill(255, 0, 255);
      text("Make sure no one is on camera and hit 'c' on the keyboard to calibrate the camera", 50, height/2-100, width-100, height-200);
    } else {
      backDiff.loadPixels();
      frameDiff.loadPixels();
      previousFrame.loadPixels();

      int movementSum = 0;
      int backgroundSum = 0;
      for (int i = 0; i < numPixels; i++) {
        color currColor = video.pixels[i];
        color prevColor = previousFrame.pixels[i];
        color backColor = mBackground.pixels[i];

        int currB = currColor & 0xFF;
        int prevB = prevColor & 0xFF;
        int backB = backColor & 0xFF;

        int backDiffB =  abs(currB - backB) & 0xFF;
        int frameDiffB = abs(currB - prevB) & 0xFF;

        movementSum += (frameDiffB>128)?frameDiffB:0;
        backgroundSum += (backDiffB>128)?backDiffB:0;

        frameDiff.pixels[i] = 0xff000000 | (frameDiffB << 16) | (frameDiffB << 8) | frameDiffB;
        backDiff.pixels[i] = 0xff000000 | (backDiffB << 16) | (backDiffB << 8) | backDiffB;
        previousFrame.pixels[i] = currColor;
      }
      previousFrame.updatePixels();

      if (showBackgroundDiff) {
        backDiff.updatePixels();
        image(backDiff, 0, 0);
      } else {
        frameDiff.updatePixels();
        image(frameDiff, 0, 0);
      }

      if ((movementSum > MOVEMENT_THRESHOLD) && (backgroundSum > BACKGROUND_THRESHOLD)) {
        println("move Sum: "+movementSum);
        println("back Sum: "+backgroundSum);
        if ((millis()-lastCaptureMillis > CAPTURE_PERIOD) && (mAudioPlayer.position() >= mAudioPlayer.length()) ) {
          mAudioPlayer.rewind();
          mAudioPlayer.play();
          lastCaptureMillis = millis();
        }
      }
    }
  }
}

void keyPressed() {
  if (key == ' ' || key == 'd' || key == 'D') {
    showBackgroundDiff = !showBackgroundDiff;
  } else if (key == 'c' || key == 'C') {
    mBackground.copy(video, 0, 0, video.width, video.height, 0, 0, video.width, video.height);
    needToCaptureBackground = false;
    image(video, 0, 0);
  }
}

