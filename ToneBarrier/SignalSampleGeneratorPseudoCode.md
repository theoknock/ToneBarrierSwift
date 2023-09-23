#  Generating signal samples

sample = sin(2π × frequency × frame / sampleRate)

// #1
for frame in 0..<Int(frameCount) {
    let sample = Float(sin(2.0 * .pi * frequency * Double(frame) / sampleRate))
    audioBuffer.floatChannelData![0][frame] = sample
}

// #2
// Generate audio signal
      double period = 44100.0 / frequency;
      byte[] buffer = new byte[1024];
      for (int i = 0; i < buffer.length/2; i+=2) {
        double angle = 2.0 * Math.PI * i / period;
        buffer[i] = (byte) (Math.sin(angle) * 127.0);
        buffer[i+1] = buffer[i];
      }
      
// #3
double period = 44100.0 / frequency;
double tau = 2.0 * Math.PI
for frame in 0..<Int(frameCount) {
    let sample = sin(tau * frame / period)
}
