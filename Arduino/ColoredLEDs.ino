const int RED_PIN = 9;
const int GREEN_PIN = 10;
const int BLUE_PIN = 11;

const uint8_t COLOR_BYTE = 'c';
const uint8_t POWER_BYTE = 'p';
const uint8_t READY_BYTE = 'r';

const int PACKET_SIZE = 5;
int bytesInBuffer = 0;
uint8_t buffer[5];

bool isOn = false;

void setup() {
   pinMode(GREEN_PIN, OUTPUT);
   pinMode(RED_PIN, OUTPUT);
   pinMode(BLUE_PIN, OUTPUT);

   Serial.begin(9600);
}

void loop() {
  while(Serial.available() > 0) {
    uint8_t readByte = Serial.read();
    //Serial.write(readByte);
    if(bytesInBuffer == 0) {
      switch(readByte) {
        case COLOR_BYTE:
        case POWER_BYTE:
          buffer[0] = readByte;
          bytesInBuffer++;
          break;
        default:
          break;
      }
    } else {
      buffer[bytesInBuffer] = readByte;
      bytesInBuffer++;
    }

    if(bytesInBuffer == PACKET_SIZE) {
      processBuffer();
      bytesInBuffer = 0;
    }
  } // while
}

void processBuffer() {
  if(!verifyChecksum()) {
    Serial.write('m');
    Serial.write(buffer[0]);
    Serial.write(buffer[1]);
    Serial.write(buffer[2]);
    Serial.write(buffer[3]);
    return;
  }
  
  if(buffer[0] == COLOR_BYTE) {
    if(!isOn) {
      Serial.write(0);
      return;
    }
    analogWrite(RED_PIN, buffer[1]);
    analogWrite(GREEN_PIN, buffer[2]);
    analogWrite(BLUE_PIN, buffer[3]);
  } else if(buffer[0] == POWER_BYTE) {
    isOn = buffer[1] == 1; Serial.write(isOn);
  }
  
}

bool verifyChecksum() {
  uint8_t sum = 0;
  for(int i = 0; i != PACKET_SIZE; i++)
    sum += buffer[i];
  return sum == 0;
}
