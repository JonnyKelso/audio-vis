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
String[] vis_names = {"Linear FFT Spectrum", "Logarithmic FFT Spectrum", "Stacked bar FFT"};
int vis_number = 0;
int current_vis = 0;

float smoothing = 0;
float[] fftReal;
float[] fftImag;
float[] fftSmooth;
float[] fftPrev;
float[] fftCurr;
int specSize;

WindowFunction[] window = {FFT.NONE, FFT.HAMMING, FFT.HANN, FFT.COSINE, FFT.TRIANGULAR, FFT.BARTLETT, FFT.BARTLETTHANN, FFT.LANCZOS, FFT.BLACKMAN, FFT.GAUSS};
String[] wlabel = {"NONE", "HAMMING", "HANN", "COSINE", "TRIANGULAR", "BARTLETT", "BARTLETTHANN", "LANCZOS", "BLACKMAN", "GAUSS"};
int[] spec_sizes = new int[vis_names.length];
int windex = 0;

int scale = 10;

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
  fft.window(window[windex]);
  specSize = fft.specSize();
  spec_sizes[0] = specSize;
  spec_sizes[1] = specSize;
  spec_sizes[2] = 1024;
  fftSmooth = new float[specSize];
  fftPrev   = new float[specSize];
  fftCurr   = new float[specSize];
  println("specsize = " + specSize); 
}


void draw()
{
  background(0);                  // black background
  stroke(255);

  // perform a forward FFT on the samples in the mix buffer,
  // which contains the mix of both the left and right channels of the file
  fft.forward( player.mix );

  switch (current_vis)
  {
  case 0:
    {
      linear_spectrum();
      break;
    }
  case 1:
    {
      logarithmic_spectrum();
      break;
    }
  case 2:
    {
      stacked_bar();
      break;
    }
  default:
    break;
  }

  drawUI();
}
void linear_spectrum()
{
  for (int i = 0; i < spec_sizes[0]; i++)
  {
    int x = int(map(i, 0, spec_sizes[0], horiz_margin, width - horiz_margin));
    // draw the line for frequency band i, scaling it by 4 so we can see it a bit better
    line(x, height - vert_margin, x, height - vert_margin - fft.getBand(i));
  }
}
void logarithmic_spectrum()
{
  fftReal = fft.getSpectrumReal();
  fftImag = fft.getSpectrumImaginary();
  for (int i = 0; i < fft.specSize(); i++)
  {
    int x = int(map(i, 0, fft.specSize(), horiz_margin, width - horiz_margin));
    fftCurr[i] = scale * (float)Math.log10(fftReal[i]*fftReal[i] + fftImag[i]*fftImag[i]);
    fftSmooth[i] = smoothing * fftSmooth[i] + ((1 - smoothing) * fftCurr[i]);

    //stroke(i, 100, 100);
    //line( i, height/2, i, height/2 - (mousePressed ? fftSmooth[i] : fftCurr[i]));
    line(x, height - vert_margin, x, height - vert_margin - fftCurr[i]);
  }
}
void stacked_bar()
{
  
  for (int i = 0; i < spec_sizes[2]; i++)
  {
    int x = int(map(i, 0, spec_sizes[2], horiz_margin, width - horiz_margin));
    // draw the line for frequency band i, scaling it by 4 so we can see it a bit better
    line(x, height - vert_margin, x, height - vert_margin - fft.getBand(i));
  }
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
      int temp = current_vis;
      temp--;
      println("temp = " + temp + ", vis_names.length = " + vis_names.length);
      if (temp < 0)
      { // wrap vis number round to the highest number
        current_vis = vis_names.length - 1;
      } else
      {
        current_vis = temp;
      }
      println("current_vis = " + current_vis);
    } else if (keyCode == RIGHT) {
      int temp = current_vis;
      temp++;
      println("temp = " + temp + ", vis_names.length = " + vis_names.length);
      if (temp == vis_names.length)
      {// wrap vis number round to the lowest number
        current_vis = 0;
      }
      else
      {
        current_vis = temp;
      }
      println("current_vis = " + current_vis);
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
  text(vis_names[current_vis], horiz_margin, vert_margin);
}