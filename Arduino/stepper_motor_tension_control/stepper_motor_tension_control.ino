/*
  Stepper Motor Tension Control System
  Controls 2 motors to reach user-specified string tensions
*/

#include <TMCStepper.h>
#include <HX711_ADC.h>

// Motor pin connections
const int MOTOR1_STEP_PIN = 31, MOTOR1_DIR_PIN = 32, MOTOR1_EN_PIN = 30;
const int MOTOR2_STEP_PIN = 25, MOTOR2_DIR_PIN = 26, MOTOR2_EN_PIN = 27;

// Load cell pin connections
const int LOADCELL1_DOUT_PIN = 2, LOADCELL1_SCK_PIN = 3;
const int LOADCELL2_DOUT_PIN = 4, LOADCELL2_SCK_PIN = 5;

// Driver settings
const float SENSE_RESISTOR = 0.11;
TMC2209Stepper driver1(&Serial1, SENSE_RESISTOR, 0);
TMC2209Stepper driver2(&Serial1, SENSE_RESISTOR, 1);

// Load cell objects
HX711_ADC LoadCell1(LOADCELL1_DOUT_PIN, LOADCELL1_SCK_PIN);
HX711_ADC LoadCell2(LOADCELL2_DOUT_PIN, LOADCELL2_SCK_PIN);

// Control variables
float targetTension1 = 0, targetTension2 = 0;
const int STEP_DELAY = 1000;  // Slower steps for precise control
const float TOLERANCE = 0.02;  // Stop when within this range of target
const float ZERO_TOLERANCE = 0.1;  // Stop when within this range of home
bool returningToZero = false;  // Flag to track when returning to zero after cancel

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
      returningToZero = true;
      Serial.println("\nOperation cancelled. Target tensions set to zero.");
      // Flush any remaining serial input
      while (Serial.available() > 0) {
        Serial.read();
      }
    }
  }
  
  // Read current tensions
  LoadCell1.update();
  LoadCell2.update();
  float tension1 = LoadCell1.getData();
  float tension2 = LoadCell2.getData();
  
  // Check if we've reached zero after cancel and should get new targets
  if (returningToZero && abs(tension1) <= ZERO_TOLERANCE && abs(tension2) <= ZERO_TOLERANCE) {
    Serial.println("Tensions returned to zero. Ready for new targets.");
    returningToZero = false;
    getUserTargets();
    return; // Skip the rest of this loop iteration
  }
  
  // Normal tension control for both motors
  float error1 = tension1 - targetTension1;
  if (abs(error1) > TOLERANCE) {
    adjustMicrosteps(1, abs(error1));
    stepMotor(1, error1 < 0);
  }
  
  float error2 = tension2 - targetTension2;
  if (abs(error2) > TOLERANCE) {
    adjustMicrosteps(2, abs(error2));
    stepMotor(2, error2 < 0);
  }
  
  // Print status for plotting (faster update rate)
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 100) {  // 10Hz update rate for plotting
    // Format for Serial Plotter: Tension1:value1 Tension2:value2 Target1:value1 Target2:value2
    Serial.print("Tension1:"); Serial.print(tension1, 2); Serial.print(" ");
    Serial.print("Tension2:"); Serial.print(tension2, 2); Serial.print(" ");
    Serial.print("Target1:"); Serial.print(targetTension1, 2); Serial.print(" ");
    Serial.print("Target2:"); Serial.println(targetTension2, 2);
    lastPrint = millis();
  }
  
  delay(30);  // 200Hz loop rate - faster but still stable
}

// Setup motor drivers
void setupMotors() {
  // Configure pins
  pinMode(MOTOR1_STEP_PIN, OUTPUT); pinMode(MOTOR1_DIR_PIN, OUTPUT); pinMode(MOTOR1_EN_PIN, OUTPUT);
  pinMode(MOTOR2_STEP_PIN, OUTPUT); pinMode(MOTOR2_DIR_PIN, OUTPUT); pinMode(MOTOR2_EN_PIN, OUTPUT);
  digitalWrite(MOTOR1_EN_PIN, HIGH); // Disable motors
  digitalWrite(MOTOR2_EN_PIN, HIGH);
  
  // Configure TMC2209 drivers
  Serial1.begin(115200);
  delay(10);
  
  driver1.begin();
  driver1.toff(5);
  driver1.I_scale_analog(false);  // false = use UART for current
  driver1.rms_current(1600);
  driver1.en_spreadCycle(false);
  driver1.pwm_autoscale(true);
  driver1.pwm_autograd(true);

  driver2.begin();
  driver2.toff(5);
  driver2.I_scale_analog(false);  // false = use UART for current
  driver2.rms_current(1600);
  driver2.en_spreadCycle(false);
  driver2.pwm_autoscale(true);
  driver2.pwm_autograd(true);

  delay(1000);
  digitalWrite(MOTOR1_EN_PIN, LOW); // Enable motors
  digitalWrite(MOTOR2_EN_PIN, LOW);
  
  Serial.println("Motors configured");
}

// Setup load cells
void setupLoadCells() {
  LoadCell1.begin();
  LoadCell2.begin();
  
  // Stabilization and tare
  unsigned long stabilizingtime = 2000;
  LoadCell1.start(stabilizingtime, true); // true = tare
  LoadCell2.start(stabilizingtime, true);
  
  // Set calibration factors (adjust these for your load cells)
  LoadCell1.setCalFactor(178000.0);
  LoadCell2.setCalFactor(178000.0);
  
  // Wait for stabilization
  while (!LoadCell1.update() || !LoadCell2.update());
  
  Serial.println("Load cells calibrated and ready");
}

// Get target tensions from user
void getUserTargets() {
  // Flush leftover serial input (e.g., '\n' from cancel 'c')
  while (Serial.available() > 0) {
    Serial.read();
  }
  Serial.println("\n--- Set Target Tensions ---");
  // Motor 1 target
  Serial.print("Enter target tension for Motor 1 (units): ");
  while (!Serial.available()) {
    // wait until user types something
  }
  targetTension1 = Serial.parseFloat();
  // clear the buffer after reading
  while (Serial.available() > 0) {
    Serial.read();
  }
  Serial.println(targetTension1, 2);
  // Motor 2 target
  Serial.print("Enter target tension for Motor 2 (units): ");
  while (!Serial.available()) {
    // wait until user types something
  }
  targetTension2 = Serial.parseFloat();
  // clear the buffer after reading
  while (Serial.available() > 0) {
    Serial.read();
  }
  Serial.println(targetTension2, 2);
  Serial.println("Targets set. Starting tension control...\n");
}

// Adjust microsteps based on distance from target (expanded proportional control)
void adjustMicrosteps(int motorNum, float error) {
  int microsteps;
  // Expanded proportional control: larger error = coarser steps (faster)
  if (error > 1.5) {
    microsteps = 8;    // Coarse steps steps when very far from target
  } else if (error > 0.75) {
    microsteps = 16;    // Medium-coarse steps
  } else if (error > 0.4) {
    microsteps = 32;   // Medium steps
  } else if (error > 0.2) {
    microsteps = 64;   // Medium-fine steps
  } else if (error > 0.1) {
    microsteps = 128;   // Fine steps
  } else if (error > 0.05) {
    microsteps = 256;  // Very fine steps
  } else {
    microsteps = 256;  // Finest steps when very close to target
  }
  
  // Apply microstep setting to appropriate driver
  if (motorNum == 1) {
    driver1.microsteps(microsteps);
  } else {
    driver2.microsteps(microsteps);
  }
}

// Step a single motor
void stepMotor(int motorNum, bool forward) {
  // digitalWrite(dirPin, LOW) is winding in
  int stepPin = (motorNum == 1) ? MOTOR1_STEP_PIN : MOTOR2_STEP_PIN;
  int dirPin = (motorNum == 1) ? MOTOR1_DIR_PIN : MOTOR2_DIR_PIN;
  
  digitalWrite(dirPin, forward ? LOW : HIGH);
  // Single step
  digitalWrite(stepPin, HIGH);
  delayMicroseconds(2);
  digitalWrite(stepPin, LOW);
  delayMicroseconds(STEP_DELAY);
}