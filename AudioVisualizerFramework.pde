import ddf.minim.analysis.*;
import ddf.minim.*;

// Globals
Minim       minim;
AudioPlayer track;
FFT         fft;

// Canvas dimensions
final double canvasWidth = 1024;
final double canvasHeight = 1024;

final int frameRate = 60;

// FFT constants
final int fftFrameSize = 128;
final int maxBin = fftFrameSize/2 + 1;


// Visual constants
enum ScaleType{LOG, LINEAR};
final ScaleType scale = ScaleType.LOG;
enum orientationType{HORIZONTAL};
final orientationType orientation = orientationType.HORIZONTAL;
enum lineType{CONNECT_THE_DOTS, BINS, CIRCLE, CIRCLE_CLOCK};
final lineType line = lineType.CIRCLE_CLOCK;
final boolean opacityModulationByBinGain = false;
final float opacityModulationByBinGainAmount = 16;

// Circle Constants
final float maxCircleThickness = 20; // max thickness
final float minCircleThickness = 1; // min thickness
final boolean circleOpacityModulationByBinGain = true;
final float circleOpacityModulationByBinGainAmount = 50;
final boolean circleThicknessModulationByBinGain = true;
final float circleThicknessModulationByBinGainAmount = .1;

// Clock circle constants
final float maxClockCircleThickness = 20; // max thickness
final float minClockCircleThickness = 10; // min thickness
final float angleIncrement = 2;
final int clearSpeed = 4;
final float circleClockThicknessModulationByBinGainAmount = .4;
final float radiusScale = 2;



public void settings() {
    size((int)canvasWidth, (int)canvasHeight);
}

void setup()
{
    // smooth(8);
    frameRate(frameRate);
    noFill();
    colorMode(RGB, 255);
    minim = new Minim(this);

    // specify that we want the audio buffers of the AudioPlayer
    // to be 1024 samples long because our FFT needs to have 
    // a power-of-two buffer size and this is a good size.
    track = minim.loadFile("/Users/jamessafko/Desktop/Reference Tracks/01 Nonplus 2 [2020-05-31 120030].wav", fftFrameSize);

    // loop the file indefinitely
    track.loop();

    // create an FFT object that has a time-domain buffer 
    // the same size as track's sample buffer
    // note that this needs to be a power of two 
    // and that it means the size of the spectrum will be half as large.
    fft = new FFT( track.bufferSize(), track.sampleRate() );
    
    background(0);
    
    
}

float angle = 0;
float prevAngle = 0;
void draw()
{
    
    if (line == lineType.CIRCLE_CLOCK) {
        //background(0);
        fill(0, clearSpeed); // clear background
        rect(0, 0, width, height);
    }
    else
        background(0); // clear background
    
    stroke(255);

    // perform a forward FFT on the samples in track's mix buffer,
    // which contains the mix of both the left and right channels of the file
    fft.forward(track.mix);

    for (int bin = 0; bin < fft.specSize(); bin++)
    {
        graphFft(bin);
    }
    
    // Increase angle for circle clock
    prevAngle = angle;
    angle += angleIncrement;
    if (angle >= 360) // make sure it wraps around
        angle -= 360;
}

// debug
float min = 99999;
float max = -9999999;

// Previous pixel information
int prevPixelX = 0;
int prevPixelY = 0;
// Circle Clock
float[] previousRadius = new float[maxBin];

void graphFft(int bin) {
    int pixelX = 0;
    int pixelY = 0;
    float radius = 0;
    
    // If this is the first bin, reset pixel positions
    if (bin == 0) {
        prevPixelX = 0;
        prevPixelY = 0;
    }
    
    switch (orientation) {
        case HORIZONTAL:
        
            // Get pixel location depending on scale
            switch (scale) {
                case LOG:
                    pixelX = binToPixelLog(bin+1, (int) canvasWidth);
                    break;
                case LINEAR:
                    pixelX = binToPixelLinear(bin, (int) track.sampleRate(), (int) canvasWidth);
                    break;
            }
            
            // If this pixel is already occupied, skip it (to save time)
            if (prevPixelX == pixelX) {
                return;
            }
                    
            float binDb = 0;
            float thickness = 0;
                    
            // Draw bin line
            switch (line) {
                // Vertical lines
                case BINS:
                    // Get bin gain in dB
                    binDb = 20 * (float) Math.log10(fft.getBand(bin));
            
                    // scale to get pixel y
                    pixelY = Math.round(16 * binDb);
                    
                    
                    // Change opacity by gain
                    if (opacityModulationByBinGain) {
                        /******************** DB GAIN COLOR *******************/
                        /**
                        float rgb = ((pixelY + 1024) / 8);
                        
                        // cap between 0 and 255
                        rgb = Math.max(0, rgb);
                        rgb = Math.min(255, rgb);
                        */
                        
                        /******************** LINEAR GAIN COLOR *******************/                       
                        stroke(fft.getBand(bin) * opacityModulationByBinGainAmount);
                    }
            
                    // Draw line
                    line(pixelX, height, pixelX, height - pixelY);
                    break;
                    
                // Continuous line
                case CONNECT_THE_DOTS:
                    // Get bin gain in dB
                    binDb = 20 * (float) Math.log10(fft.getBand(bin));
                    
                    // scale to get pixel y
                    pixelY = Math.round(16 * binDb);
                    
                    line(prevPixelX, height - prevPixelY, pixelX, height - pixelY);
                    break;
                    
                case CIRCLE:
                
                    // Circle opacity
                    if (circleOpacityModulationByBinGain)
                        stroke(fft.getBand(bin) * circleOpacityModulationByBinGainAmount);
                    
                    // Circle thickness
                    thickness = (maxCircleThickness - 
                                ((float)pixelX / (float)canvasWidth) * 
                                    (maxCircleThickness - minCircleThickness)); // thickness reduced as freq increases
                    
                    // width modulated by bin gain
                    if (circleThicknessModulationByBinGain) {
                        thickness *= fft.getBand(bin) * circleThicknessModulationByBinGainAmount;
                    }
                    
                    strokeWeight(thickness);
                                        
                    circle((float)canvasWidth/2.0, (float)canvasHeight/2.0, (float)pixelX);
                    break;
                    
                case CIRCLE_CLOCK:
                    // Circle opacity
                    // if (circleOpacityModulationByBinGain)
                        // stroke(fft.getBand(bin) * circleOpacityModulationByBinGainAmount);
                    
                    // Circle thickness
                    thickness = (maxClockCircleThickness - 
                                ((float)pixelX / (float)canvasWidth) * 
                                    (maxClockCircleThickness - minClockCircleThickness)); // thickness reduced as freq increases
                    
                    // width modulated by bin gain
                    if (circleThicknessModulationByBinGain) {
                        thickness *= fft.getBand(bin) * circleClockThicknessModulationByBinGainAmount;
                    }
                    
                    // strokeWeight(thickness);
                    
                    // Radius of this
                    radius = (float) (pixelX / radiusScale + thickness);
                    
                    // X, Y location of this
                    float x = radius * cos(angle * 2 * PI / 360.0) + width/2;
                    float y = radius * sin(angle * 2 * PI / 360.0) + height/2;
                    float xPrev = previousRadius[bin] * cos(prevAngle * 2 * PI / 360.0) + width/2;
                    float yPrev = previousRadius[bin] * sin(prevAngle * 2 * PI / 360.0) + height/2;
                    
                    // Need center to be center of screen for polar coordinates
                    //translate(width/2, height/2);
                    //pushMatrix();
                    line(xPrev, yPrev, x, y);
                    //popMatrix();
                    break;                    
            }
    
            break;
    }
    
    // Update previous indexes
    prevPixelX = pixelX;
    prevPixelY = pixelY;
    
    previousRadius[bin] = radius;
}

int binToPixelLinear(int bin, int fs, int pixelWidth) {
    // Linear mapping over frequency
    double freq = (double)((bin * fs) / fftFrameSize);

    // (Freq --> percentage width) * width
    return (int) Math.round((freq / (fs / 2.0)) * pixelWidth);
}


// Constants for mapping to log space
final double y1 = maxBin; // linear bins max
final double y2 = 1; // linear bins min
final double x1 = 1; // log screen percentage max
final double x2 = 0; // log screen percentage min
final double b = Math.log10(y1 / y2)/(x1 - x2);
final double a = y1 / (Math.pow(10, b * x1)); 
int binToPixelLog(int bin, int pixelWidth) {    
    return (int) Math.round( Math.log10(bin / a) / b * pixelWidth);
}
