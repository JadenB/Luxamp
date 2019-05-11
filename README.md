<h1 align="center">
<br>
<img src="https://i.imgur.com/7qYqlpV.png" alt="logo" width="100">
<br>
Luxamp
<br>
<br>
</h1>

<h4 align="center">A fully customizable light show for your music.</h4>

**Luxamp for macOS** allows you to sync your LED lights to music with just an Arduino and a simple circuit. It analyzes audio from your computer's input and converts it into a vivid spectrum of colors for your lights. Every aspect of the conversion is customizable, including the smoothness, the frequency range used to determine color, and the output colors themselves.

![](https://i.imgur.com/YiOsI1h.gif)

## Getting started

### What you'll need
1. [This Arduino circuit](https://www.makeuseof.com/tag/connect-led-light-strips-arduino/) courtesy of MakeUseOf
2. An LED strip (SMD 5050 strip recommended).
3. A computer running macOS.

### Setting it up
1. Connect the LED strip to your circuit and connect the Arduino to your computer via USB.
2. Load the code from /Arduino/ColoredLEDs.ino onto your Arduino.
3. Build the AudioLED app.
4. Set the sound input you want to use for the lights in System Preferences.
5. Launch the app and enjoy your light show!

## Features

- Sync LED lights to your computer's audio input.
- **Fully customizable** so you can get your lights looking exactly the way you want.
- **Presets** allow you to save your favorite settings.
- **Manual mode** for when you want to use your lights without music.
- **Works with Arduino** and easily portable to any other microcontroller.
