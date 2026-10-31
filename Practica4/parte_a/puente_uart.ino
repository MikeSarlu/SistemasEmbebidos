#include <Arduino.h>

static const int FPGA_RX_PIN = 16;   // RX del ESP32 <- TX de la FPGA
static const int FPGA_TX_PIN = 17;   // TX del ESP32 -> RX de la FPGA

static const uint32_t PC_BAUD   = 9600;
static const uint32_t FPGA_BAUD = 9600;

HardwareSerial FPGA_Serial(2);

void setup() {
  Serial.begin(PC_BAUD);
  delay(500);
  FPGA_Serial.begin(FPGA_BAUD, SERIAL_8N1, FPGA_RX_PIN, FPGA_TX_PIN);
  // Se eliminó Serial.println("ESP32 listo..."): el puente debe ser transparente
}

void loop() {
  while (Serial.available()) {
    uint8_t dato = (uint8_t)Serial.read();
    FPGA_Serial.write(dato);
  }
  while (FPGA_Serial.available()) {
    uint8_t dato = (uint8_t)FPGA_Serial.read();
    Serial.write(dato);
  }
}
