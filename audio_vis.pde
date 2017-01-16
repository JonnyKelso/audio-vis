import ddf.minim.*; //<>// //<>//
import ddf.minim.analysis.*;

Minim       minim;
AudioPlayer player;
FFT         fft;

boolean playing = true;
int vis_width = 640;
int vis_height = 480;
int horiz_margin = 100;
int vert_margin = 100;
boolean debug_spectrum = true;
String audio_file = "disorder.mp3";
int y_datum = 0;
String vis_name = "Linear FFT Spectrum";

void setup()
{
  size(640, 480);
  stroke(255, 255, 255);  // white pen, with a touch of alpha
  strokeWeight(1); 

  y_datum = height - vert_margin;
  minim = new Minim(this);

  setup_audio();
}

void setup_audio()
{
  // specify that we want the audio buffers of the AudioPlayer
  // to be 1024 samples long because our FFT needs to have 
  // a power-of-two buffer size and this is a good size.
  player = minim.loadFile(audio_file, 1024);

  // loop the file indefinitely
  player.loop();

  // create an FFT object that has a time-domain buffer 
  // the same size as player's sample buffer
  // note that this needs to be a power of two 
  // and that it means the size of the spectrum will be half as large.
  fft = new FFT( player.bufferSize(), player.sampleRate() );
}


void draw()
{
  background(0);                  // black background

  // plot a 2D spectrum
  if (debug_spectrum)
  {
    for (int i = 0; i < fft.specSize(); i++)
    {
      int x = int(map(i, 0, fft.specSize(), horiz_margin, width - horiz_margin));
      // draw the line for frequency band i, scaling it by 4 so we can see it a bit better
      line(x, height - vert_margin, x, height - vert_margin - fft.getBand(i));
    }
  }

  // perform a forward FFT on the samples in the mix buffer,
  // which contains the mix of both the left and right channels of the file
  fft.forward( player.mix );

  drawUI();
}
// pause audio if mouse button is clicked
void keyPressed()
{
  if (key == 'p' || key == 'P')
  {
    if ( player.isPlaying() )
    {
      player.pause();
    } else
    {
      // simply call loop again to resume playing from where it was paused
      player.loop();
    }
  } else if (key == 'l' || key == 'L')
  {
    selectInput("Select a file to process:", "fileSelected");
  } else if (key == 'm' || key == 'M')
  {
    if (player.isMuted() )
    {
      player.unmute();
    } else
    {
      player.mute();
    }
  }

  if (key == CODED) {
    if (keyCode == LEFT) {
      // TODO - switch vis
    } else if (keyCode == RIGHT) {
      // TODO - switch vis
    }
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    audio_file = selection.getAbsolutePath();
    player.pause();
    setup_audio();
  }
}

// show text instructions for use
void drawUI()
{
  fill(255, 255, 255);
  textSize(22);
  text("press '<- / ->' to switch visualisation", 10, height - vert_margin + 50);
  text("press 'M' to mute", 10, height - vert_margin + 70);
  text(vis_name, width / 2, vert_margin);
}