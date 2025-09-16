/*
  TMC2209 Multiple Motor Controller - Individual Control
*/

#include <TMCStepper.h>

// Pin connections
const int MOTOR1_STEP_PIN = 22, MOTOR1_DIR_PIN = 23, MOTOR1_EN_PIN = 24;
const int MOTOR2_STEP_PIN = 25, MOTOR2_DIR_PIN = 26, MOTOR2_EN_PIN = 27;

// Driver settings
const float SENSE_RESISTOR = 0.11;

// Create separate driver objects with different UART addresses
TMC2209Stepper driver1(&Serial1, SENSE_RESISTOR, 0);  // Address 0 (MS1=LOW, MS2=LOW)
TMC2209Stepper driver2(&Serial1, SENSE_RESISTOR, 1);  // Address 1 (MS1=HIGH, MS2=LOW)

// Movement settings
const int STEPS_PER_REV = 200 * 16;  // Assuming 16 microsteps for both
const int STEP_DELAY = 800;

void setup() {
  Serial.begin(115200);
  
  // Set pins as outputs and enable motors
  pinMode(MOTOR1_STEP_PIN, OUTPUT); pinMode(MOTOR1_DIR_PIN, OUTPUT); pinMode(MOTOR1_EN_PIN, OUTPUT);
  pinMode(MOTOR2_STEP_PIN, OUTPUT); pinMode(MOTOR2_DIR_PIN, OUTPUT); pinMode(MOTOR2_EN_PIN, OUTPUT);
  digitalWrite(MOTOR1_EN_PIN, LOW);
  digitalWrite(MOTOR2_EN_PIN, LOW);
  
  // Start UART communication
  Serial1.begin(115200);
  delay(10);
  
  // Configure Motor 1 (driver1)
  driver1.begin();
  driver1.toff(5);
  driver1.rms_current(1500);        // Motor 1: Current in mA (set to 60-80% of rated current)
  driver1.microsteps(32);           // Motor 1: 16 microsteps
  driver1.en_spreadCycle(false);
  driver1.pwm_autoscale(true);
  driver1.pwm_autograd(true);
  
  // Configure Motor 2 (driver2) - different settings!
  driver2.begin();
  driver2.toff(5);
  driver2.rms_current(1500);         // Motor 2: 800mA (different current)
  driver2.microsteps(32);            // Motor 2: 8 microsteps (different microstepping)
  driver2.en_spreadCycle(false);
  driver2.pwm_autoscale(true);
  driver2.pwm_autograd(true);
  
  Serial.println("Both TMC2209s configured with individual settings");
  delay(500);
}

void loop() {
  Serial.println("Forward");
  moveMotors(STEPS_PER_REV, true);
  delay(300);
  
  Serial.println("Backward");
  moveMotors(STEPS_PER_REV, false);
  delay(600);
}

// Move both motors (they can have different settings but same step count)
void moveMotors(int steps, bool forward) {
  digitalWrite(MOTOR1_DIR_PIN, forward ? HIGH : LOW);
  digitalWrite(MOTOR2_DIR_PIN, forward ? HIGH : LOW);
  
  for (int i = 0; i < steps; i++) {
    digitalWrite(MOTOR1_STEP_PIN, HIGH);
    digitalWrite(MOTOR2_STEP_PIN, HIGH);
    delayMicroseconds(2);
    digitalWrite(MOTOR1_STEP_PIN, LOW);
    digitalWrite(MOTOR2_STEP_PIN, LOW);
    delayMicroseconds(STEP_DELAY);
  }
}