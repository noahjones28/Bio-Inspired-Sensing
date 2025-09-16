/*
  Stepper Motor Tension Control System
  Controls 2 motors to reach user-specified string tensions
*/

#include <TMCStepper.h>
#include <HX711_ADC.h>

// Motor pin connections
const int MOTOR1_STEP_PIN = 22, MOTOR1_DIR_PIN = 23, MOTOR1_EN_PIN = 24;
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
const float TOLERANCE = 0.1;  // Stop when within this range of target
bool cancelOperation = false;

void setup() {
  Serial.begin(115200);
  Serial.println("Tension Control System Starting...");
  
  setupMotors();
  setupLoadCells();
  getUserTargets();
  
  Serial.println("System ready. Motors will adjust to target tensions.");
  Serial.println("Send 'c' anytime to cancel and return to zero tension.");
}

void loop() {
  // Check for cancel command
  if (Serial.available() > 0) {
    char command = Serial.read();
    if (command == 'c' || command == 'C') {
      cancelOperation = true;
      Serial.println("\nOperation cancelled. Returning tensions to zero...");
    }
  }
  
  // Read current tensions
  LoadCell1.update();
  LoadCell2.update();
  float tension1 = LoadCell1.getData();
  float tension2 = LoadCell2.getData();
  
  if (cancelOperation) {
    // Return both tensions to zero
    if (abs(tension1) > TOLERANCE) {
      adjustMicrosteps(1, abs(tension1));
      stepMotor(1, tension1 > 0);  // Step to reduce tension
    }
    if (abs(tension2) > TOLERANCE) {
      adjustMicrosteps(2, abs(tension2));
      stepMotor(2, tension2 > 0);  // Step to reduce tension
    }
    
    // Check if both are at zero
    if (abs(tension1) <= TOLERANCE && abs(tension2) <= TOLERANCE) {
      Serial.println("Tensions returned to zero. Ready for new targets.");
      cancelOperation = false;
      getUserTargets();  // Get new targets
    }
  } else {
    // Normal tension control
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
  digitalWrite(MOTOR1_EN_PIN, LOW); // Enable motors
  digitalWrite(MOTOR2_EN_PIN, LOW);
  
  // Set direction for tensioning (adjust if motors wind opposite directions)
  digitalWrite(MOTOR1_DIR_PIN, LOW); // Forward = increase tension
  digitalWrite(MOTOR2_DIR_PIN, LOW);
  
  // Configure TMC2209 drivers
  Serial1.begin(115200);
  delay(10);
  
  driver1.begin();
  driver1.toff(5);
  driver1.rms_current(1500);
  driver1.microsteps(32);
  driver1.en_spreadCycle(false);
  driver1.pwm_autoscale(true);
  driver1.pwm_autograd(true);
  
  driver2.begin();
  driver2.toff(5);
  driver2.rms_current(1500);
  driver2.microsteps(32);
  driver2.en_spreadCycle(false);
  driver2.pwm_autoscale(true);
  driver2.pwm_autograd(true);
  
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
  Serial.println("\n--- Set Target Tensions ---");
  
  Serial.print("Enter target tension for Motor 1 (units): ");
  while (!Serial.available()) {} // Wait for input
  targetTension1 = Serial.parseFloat();
  while (Serial.available()) Serial.read(); // Clear buffer
  Serial.println(targetTension1, 2);
  
  Serial.print("Enter target tension for Motor 2 (units): ");
  while (!Serial.available()) {} // Wait for input
  targetTension2 = Serial.parseFloat();
  while (Serial.available()) Serial.read(); // Clear buffer
  Serial.println(targetTension2, 2);
  
  Serial.println("Targets set. Starting tension control...\n");
}

// Adjust microsteps based on distance from target (expanded proportional control)
void adjustMicrosteps(int motorNum, float error) {
  int microsteps;
  
  // Expanded proportional control: larger error = coarser steps (faster)
  if (error > 3.0) {
    microsteps = 2;    // Coarsest steps when very far from target
  } else if (error > 1.5) {
    microsteps = 4;    // Coarse steps
  } else if (error > 0.75) {
    microsteps = 8;    // Medium-coarse steps
  } else if (error > 0.4) {
    microsteps = 16;   // Medium steps
  } else if (error > 0.2) {
    microsteps = 32;   // Medium-fine steps
  } else if (error > 0.1) {
    microsteps = 64;   // Fine steps
  } else if (error > 0.05) {
    microsteps = 128;  // Very fine steps
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
  int stepPin = (motorNum == 1) ? MOTOR1_STEP_PIN : MOTOR2_STEP_PIN;
  int dirPin = (motorNum == 1) ? MOTOR1_DIR_PIN : MOTOR2_DIR_PIN;
  
  digitalWrite(dirPin, forward ? HIGH : LOW);
  
  // Single step
  digitalWrite(stepPin, HIGH);
  delayMicroseconds(2);
  digitalWrite(stepPin, LOW);
  delayMicroseconds(STEP_DELAY);
}