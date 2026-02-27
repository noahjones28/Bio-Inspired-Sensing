/*
  Stepper Motor Tension Control System
  Controls 5 motors to reach user-specified string tensions
*/

#include <TMCStepper.h>
#include <HX711_ADC.h>

// Motor pin connections
const int MOTOR1_STEP_PIN = 31, MOTOR1_DIR_PIN = 32, MOTOR1_EN_PIN = 30;
const int MOTOR2_STEP_PIN = 34, MOTOR2_DIR_PIN = 35, MOTOR2_EN_PIN = 33;
const int MOTOR3_STEP_PIN = 37, MOTOR3_DIR_PIN = 38, MOTOR3_EN_PIN = 36;
const int MOTOR4_STEP_PIN = 40, MOTOR4_DIR_PIN = 41, MOTOR4_EN_PIN = 39;
const int MOTOR5_STEP_PIN = 43, MOTOR5_DIR_PIN = 44, MOTOR5_EN_PIN = 42;

// Load cell pin connections
const int LOADCELL1_DOUT_PIN = 2, LOADCELL1_SCK_PIN = 3;
const int LOADCELL2_DOUT_PIN = 4, LOADCELL2_SCK_PIN = 5;
const int LOADCELL3_DOUT_PIN = 6, LOADCELL3_SCK_PIN = 7;
const int LOADCELL4_DOUT_PIN = 8, LOADCELL4_SCK_PIN = 9;
const int LOADCELL5_DOUT_PIN = 10, LOADCELL5_SCK_PIN = 11;

// Driver settings
const float SENSE_RESISTOR = 0.11;
TMC2209Stepper driver1(&Serial1, SENSE_RESISTOR, 0);
TMC2209Stepper driver2(&Serial1, SENSE_RESISTOR, 1);
TMC2209Stepper driver3(&Serial1, SENSE_RESISTOR, 2);
TMC2209Stepper driver4(&Serial1, SENSE_RESISTOR, 3);
TMC2209Stepper driver5(&Serial2, SENSE_RESISTOR, 0);

// Load cell objects
HX711_ADC LoadCell1(LOADCELL1_DOUT_PIN, LOADCELL1_SCK_PIN);
HX711_ADC LoadCell2(LOADCELL2_DOUT_PIN, LOADCELL2_SCK_PIN);
HX711_ADC LoadCell3(LOADCELL3_DOUT_PIN, LOADCELL3_SCK_PIN);
HX711_ADC LoadCell4(LOADCELL4_DOUT_PIN, LOADCELL4_SCK_PIN);
HX711_ADC LoadCell5(LOADCELL5_DOUT_PIN, LOADCELL5_SCK_PIN);

// Load cell calibration factor
const float CALIBRATION_FACTOR = 130000.0;

// Control variables
float targetTension1 = 0, targetTension2 = 0, targetTension3 = 0, targetTension4 = 0, targetTension5 = 0;
const float TOLERANCE = 0.03;       // Stop when within this range of target
const float ZERO_TOLERANCE = 0.05;  // Stop when within this range of home
bool returningToZero = false;       // Flag to track when returning to zero after cancel

// NEW: Per-motor timing for delay-based speed control
unsigned long lastStepTime[5] = {0, 0, 0, 0, 0};

void setup() {
  Serial.begin(115200);
  Serial.println("Tension Control System Starting...");
  
  setupMotors();
  setupLoadCells();
  getUserTargets();
  
  Serial.println("System ready. Motors will adjust to target tensions.");
  Serial.println("Send 'c' anytime to cancel and set tensions to zero.");
}

void loop() {
  // Check for cancel command
  if (Serial.available() > 0) {
    char command = Serial.read();
    if (command == 'c' || command == 'C') {
      targetTension1 = 0;
      targetTension2 = 0;
      targetTension3 = 0;
      targetTension4 = 0;
      targetTension5 = 0;
      returningToZero = true;
      Serial.println("\nOperation cancelled. Target tensions set to zero.");
      while (Serial.available() > 0) {
        Serial.read();
      }
    }
  }
  
  // Read current tensions
  LoadCell1.update();
  LoadCell2.update();
  LoadCell3.update();
  LoadCell4.update();
  LoadCell5.update();
  float tension1 = LoadCell1.getData();
  float tension2 = LoadCell2.getData();
  float tension3 = LoadCell3.getData();
  float tension4 = LoadCell4.getData();
  float tension5 = LoadCell5.getData();
  
  // Check if we've reached zero after cancel and should get new targets
  if (returningToZero && 
      abs(tension1) <= ZERO_TOLERANCE && abs(tension2) <= ZERO_TOLERANCE &&
      abs(tension3) <= ZERO_TOLERANCE && abs(tension4) <= ZERO_TOLERANCE &&
      abs(tension5) <= ZERO_TOLERANCE) {
    Serial.println("Tensions returned to zero. Ready for new targets.");
    returningToZero = false;
    getUserTargets();
    return;
  }
  
  // NEW: Delay-based tension control — 1 step per motor per interval
  int stepPins[] = {MOTOR1_STEP_PIN, MOTOR2_STEP_PIN, MOTOR3_STEP_PIN, MOTOR4_STEP_PIN, MOTOR5_STEP_PIN};
  int dirPins[]  = {MOTOR1_DIR_PIN, MOTOR2_DIR_PIN, MOTOR3_DIR_PIN, MOTOR4_DIR_PIN, MOTOR5_DIR_PIN};
  float errors[] = {tension1 - targetTension1, tension2 - targetTension2, tension3 - targetTension3,
                    tension4 - targetTension4, tension5 - targetTension5};

  unsigned long now = micros();
  for (int i = 0; i < 5; i++) {
    if (abs(errors[i]) > TOLERANCE && (now - lastStepTime[i]) >= delayForError(errors[i])) {
      stepMotor1(stepPins[i], dirPins[i], errors[i] < 0);
      lastStepTime[i] = now;
    }
  }
  
  // Print status for plotting (10Hz update rate)
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 100) {
    Serial.print("Tendon Tensions[N]: ");
    Serial.print(tension1, 2); Serial.print(", ");
    Serial.print(tension2, 2); Serial.print(", ");
    Serial.print(tension3, 2);

    Serial.print(" | Forces[N]: ");
    Serial.print(tension4, 2); Serial.print(", ");
    Serial.print(tension5, 2);

    Serial.print(" | Targets: ");
    Serial.print(targetTension1, 2); Serial.print(", ");
    Serial.print(targetTension2, 2); Serial.print(", ");
    Serial.print(targetTension3, 2); Serial.print(", ");
    Serial.print(targetTension4, 2); Serial.print(", ");
    Serial.println(targetTension5, 2);
    lastPrint = millis();
  }

}

// ---- Motor Control ----

void setupMotors() {
  pinMode(MOTOR1_STEP_PIN, OUTPUT); pinMode(MOTOR1_DIR_PIN, OUTPUT); pinMode(MOTOR1_EN_PIN, OUTPUT);
  pinMode(MOTOR2_STEP_PIN, OUTPUT); pinMode(MOTOR2_DIR_PIN, OUTPUT); pinMode(MOTOR2_EN_PIN, OUTPUT);
  pinMode(MOTOR3_STEP_PIN, OUTPUT); pinMode(MOTOR3_DIR_PIN, OUTPUT); pinMode(MOTOR3_EN_PIN, OUTPUT);
  pinMode(MOTOR4_STEP_PIN, OUTPUT); pinMode(MOTOR4_DIR_PIN, OUTPUT); pinMode(MOTOR4_EN_PIN, OUTPUT);
  pinMode(MOTOR5_STEP_PIN, OUTPUT); pinMode(MOTOR5_DIR_PIN, OUTPUT); pinMode(MOTOR5_EN_PIN, OUTPUT);
  digitalWrite(MOTOR1_EN_PIN, HIGH);
  digitalWrite(MOTOR2_EN_PIN, HIGH);
  digitalWrite(MOTOR3_EN_PIN, HIGH);
  digitalWrite(MOTOR4_EN_PIN, HIGH);
  digitalWrite(MOTOR5_EN_PIN, HIGH);
  
  Serial1.begin(115200);
  Serial2.begin(115200);
  delay(10);
  
  initDriver(driver1);
  initDriver(driver2);
  initDriver(driver3);
  initDriver(driver4);
  initDriver(driver5);

  // Fixed microsteps at 256 for all drivers
  driver1.microsteps(256);
  driver2.microsteps(256);
  driver3.microsteps(256);
  driver4.microsteps(256);
  driver5.microsteps(256);

  delay(1000);
  digitalWrite(MOTOR1_EN_PIN, LOW);
  digitalWrite(MOTOR2_EN_PIN, LOW);
  digitalWrite(MOTOR3_EN_PIN, LOW);
  digitalWrite(MOTOR4_EN_PIN, LOW);
  digitalWrite(MOTOR5_EN_PIN, LOW);
  
  Serial.println("Motors configured");
}

void initDriver(TMC2209Stepper &drv) {
  drv.begin();
  drv.toff(5);
  drv.I_scale_analog(false);
  drv.rms_current(1000);
  drv.en_spreadCycle(false);
  drv.pwm_autoscale(true);
  drv.pwm_autograd(true);
}

// NEW: Returns minimum microseconds between steps based on error magnitude
// Large error = short delay = fast stepping, small error = long delay = slow stepping
unsigned long delayForError(float error) {
  float absErr = abs(error);
  if (absErr > 0.75)  return 50;    // ~20,000 steps/sec (fastest)
  if (absErr > 0.5)  return 400;    // ~2,500 steps/sec
  if (absErr > 0.2)  return 1000;   // ~1,000 steps/sec
  if (absErr > 0.1)  return 2500;   // ~400 steps/sec
  return 5000;                       // ~200 steps/sec (slowest, fine approach)
}

// NEW: Single-step pulse (no loop, no blocking delay)
void stepMotor1(int stepPin, int dirPin, bool forward) {
  digitalWrite(dirPin, forward ? LOW : HIGH);
  digitalWrite(stepPin, HIGH);
  delayMicroseconds(2);
  digitalWrite(stepPin, LOW);
}

// ---- Load Cells ----

void setupLoadCells() {
  LoadCell1.begin();
  LoadCell2.begin();
  LoadCell3.begin();
  LoadCell4.begin();
  LoadCell5.begin();
  
  unsigned long stabilizingtime = 2000;
  LoadCell1.start(stabilizingtime, true);
  LoadCell2.start(stabilizingtime, true);
  LoadCell3.start(stabilizingtime, true);
  LoadCell4.start(stabilizingtime, true);
  LoadCell5.start(stabilizingtime, true);
  
  LoadCell1.setCalFactor(CALIBRATION_FACTOR);
  LoadCell2.setCalFactor(CALIBRATION_FACTOR);
  LoadCell3.setCalFactor(CALIBRATION_FACTOR);
  LoadCell4.setCalFactor(CALIBRATION_FACTOR);
  LoadCell5.setCalFactor(CALIBRATION_FACTOR);
  
  while (!LoadCell1.update() || !LoadCell2.update() || !LoadCell3.update() || !LoadCell4.update() || !LoadCell5.update());
  
  Serial.println("Load cells calibrated and ready");
}

// ---- User Input ----

void getUserTargets() {
  while (Serial.available() > 0) {
    Serial.read();
  }
  Serial.println("\n--- Set Targets ---");

  Serial.print("Enter target tension for tendon 1 (N): ");
  while (!Serial.available()) {}
  targetTension1 = Serial.parseFloat();
  while (Serial.available() > 0) { Serial.read(); }
  Serial.println(targetTension1, 2);

  Serial.print("Enter target tension for tendon 2 (N): ");
  while (!Serial.available()) {}
  targetTension2 = Serial.parseFloat();
  while (Serial.available() > 0) { Serial.read(); }
  Serial.println(targetTension2, 2);

  Serial.print("Enter target tension for tendon 3 (N): ");
  while (!Serial.available()) {}
  targetTension3 = Serial.parseFloat();
  while (Serial.available() > 0) { Serial.read(); }
  Serial.println(targetTension3, 2);

  Serial.print("Enter target for Force 1 (N): ");
  while (!Serial.available()) {}
  targetTension4 = Serial.parseFloat();
  while (Serial.available() > 0) { Serial.read(); }
  Serial.println(targetTension4, 2);

  Serial.print("Enter target for Force 2 (N): ");
  while (!Serial.available()) {}
  targetTension5 = Serial.parseFloat();
  while (Serial.available() > 0) { Serial.read(); }
  Serial.println(targetTension5, 2);

  Serial.println("Targets set. Starting tension control...\n");
}
