/*
Note: N channels = 4
Note: Checksum operates on all bytes between the start delimiter and itself
 
Channels:
0 - Dimmer
1 - Color R
2 - Color G
3 - Color B

Incomning write channels packet structure:
|start delimiter| 1 byte
|write channels opcode| 1 byte
|channel values| 4 bytes
|checksum| 1 byte
|end delimiter| 1 byte

Incoming request packet structure:
|start delimiter| 1 byte
|request opcode| 1 byte
|request type| 1 byte
|request parameters (request type dependant)| N-1 bytes
|checksum| 1 byte
|end delimiter| 1 byte

Outgoing response structure:
|start delimiter| 1 byte
|request type| 1 byte
|response code| 1 byte
|checksum| 1 byte
|end delimiter| 1 byte
*/

#define RED_PIN 9
#define GREEN_PIN 10
#define BLUE_PIN 11

const uint8_t GAMMA_LOOKUP[256] = {
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2,
  3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6,
  6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 11, 11, 11, 12,
  12, 13, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19,
  20, 20, 21, 22, 22, 23, 23, 24, 25, 25, 26, 26, 27, 28, 28, 29,
  30, 30, 31, 32, 33, 33, 34, 35, 35, 36, 37, 38, 39, 39, 40, 41,
  42, 43, 43, 44, 45, 46, 47, 48, 49, 49, 50, 51, 52, 53, 54, 55,
  56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
  73, 74, 75, 76, 77, 78, 79, 81, 82, 83, 84, 85, 87, 88, 89, 90,
  91, 93, 94, 95, 97, 98, 99, 100, 102, 103, 105, 106, 107, 109, 110, 111,
  113, 114, 116, 117, 119, 120, 121, 123, 124, 126, 127, 129, 130, 132, 133, 135,
  137, 138, 140, 141, 143, 145, 146, 148, 149, 151, 153, 154, 156, 158, 159, 161,
  163, 165, 166, 168, 170, 172, 173, 175, 177, 179, 181, 182, 184, 186, 188, 190,
  192, 194, 196, 197, 199, 201, 203, 205, 207, 209, 211, 213, 215, 217, 219, 221,
  223, 225, 227, 229, 231, 234, 236, 238, 240, 242, 244, 246, 248, 251, 253, 255 };

const int PACKET_SIZE = 8;

const int START_BYTE_INDEX = 0;
const int OPCODE_INDEX = 1;
const int CHANNEL_DIMMER_INDEX = 2;
const int CHANNEL_R_INDEX = 3;
const int CHANNEL_G_INDEX = 4;
const int CHANNEL_B_INDEX = 5;
const int CHECKSUM_INDEX = 6;
const int END_BYTE_INDEX = 7;

const uint8_t START_BYTE = 0xE7;
const uint8_t END_BYTE = 0x7E;

const uint8_t REQUEST_OPCODE = 0x3F; // '?'
const uint8_t WRITE_CHANNELS_OPCODE = 0x57; // 'W'

const uint8_t READY_REQUEST_TYPE = 0x72; // 'r'

int buffer_loc = 0;
uint8_t cur_checksum = 0;
uint8_t buffer[PACKET_SIZE];

uint8_t compute_single_color_output(uint8_t dimmer_val, uint8_t single_color_val) {
  float dimmer_val_f = (float)dimmer_val / 255.0f;
  single_color_val = (uint8_t)((float)single_color_val * dimmer_val_f);
  return GAMMA_LOOKUP[single_color_val];
}

void process_write_channels() {
  analogWrite(RED_PIN, compute_single_color_output(buffer[CHANNEL_DIMMER_INDEX], buffer[CHANNEL_R_INDEX]));
  analogWrite(GREEN_PIN, compute_single_color_output(buffer[CHANNEL_DIMMER_INDEX], buffer[CHANNEL_G_INDEX]));
  analogWrite(BLUE_PIN, compute_single_color_output(buffer[CHANNEL_DIMMER_INDEX], buffer[CHANNEL_B_INDEX]));
}

void process_ready_request() {
  uint8_t response_checksum = 0;
  Serial.write(START_BYTE);
  Serial.write(READY_REQUEST_TYPE); response_checksum += READY_REQUEST_TYPE;
  Serial.write(1); response_checksum += 1;
  Serial.write(response_checksum);
  Serial.write(END_BYTE);
}

void process_buffer() {
  if (buffer[OPCODE_INDEX] == WRITE_CHANNELS_OPCODE) {
    process_write_channels();
  } else if (buffer[OPCODE_INDEX] == REQUEST_OPCODE) {
    process_ready_request();
  }
}

void setup() {
   pinMode(GREEN_PIN, OUTPUT);
   pinMode(RED_PIN, OUTPUT);
   pinMode(BLUE_PIN, OUTPUT);

   Serial.begin(57600);
}

void loop() {
  while(Serial.available() > 0) {
    uint8_t read_byte = Serial.read();
    
    Serial.print(buffer_loc, DEC); 
    Serial.print(": 0x");
    Serial.print(read_byte, HEX);
    Serial.print("\n");
    
    buffer[buffer_loc] = read_byte;

    switch(buffer_loc) {
    case START_BYTE_INDEX:
      if (read_byte == START_BYTE) { buffer_loc++; }
      break;
    case CHECKSUM_INDEX:
      if (read_byte == cur_checksum) { buffer_loc++; }
      else { buffer_loc = START_BYTE_INDEX; }
      cur_checksum = 0;
      break;
    case END_BYTE_INDEX:
      if (read_byte == END_BYTE) { process_buffer(); }
      buffer_loc = START_BYTE_INDEX;
      break;
    default:
      cur_checksum += read_byte;
      buffer_loc++;
      break;
    }
  } // while
} // loop()
