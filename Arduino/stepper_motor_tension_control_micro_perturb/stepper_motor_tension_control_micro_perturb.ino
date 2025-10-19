/*
  Stepper Motor Tension Control System
  Controls 4 motors to reach user-specified string tensions
*/

#include <TMCStepper.h>
#include <HX711_ADC.h>

// Motor pin connections
const int MOTOR1_STEP_PIN = 31, MOTOR1_DIR_PIN = 32, MOTOR1_EN_PIN = 30;
const int MOTOR2_STEP_PIN = 34, MOTOR2_DIR_PIN = 35, MOTOR2_EN_PIN = 33;
const int MOTOR3_STEP_PIN = 37, MOTOR3_DIR_PIN = 38, MOTOR3_EN_PIN = 36;
const int MOTOR4_STEP_PIN = 40, MOTOR4_DIR_PIN = 41, MOTOR4_EN_PIN = 39;

// Load cell pin connections
const int LOADCELL1_DOUT_PIN = 2, LOADCELL1_SCK_PIN = 3;
const int LOADCELL2_DOUT_PIN = 4, LOADCELL2_SCK_PIN = 5;
const int LOADCELL3_DOUT_PIN = 6, LOADCELL3_SCK_PIN = 7;
const int LOADCELL4_DOUT_PIN = 8, LOADCELL4_SCK_PIN = 9;

// Driver settings
const float SENSE_RESISTOR = 0.11;
TMC2209Stepper driver1(&Serial1, SENSE_RESISTOR, 0);
TMC2209Stepper driver2(&Serial1, SENSE_RESISTOR, 1);
TMC2209Stepper driver3(&Serial1, SENSE_RESISTOR, 2);
TMC2209Stepper driver4(&Serial1, SENSE_RESISTOR, 3);

// Load cell objects
HX711_ADC LoadCell1(LOADCELL1_DOUT_PIN, LOADCELL1_SCK_PIN);
HX711_ADC LoadCell2(LOADCELL2_DOUT_PIN, LOADCELL2_SCK_PIN);
HX711_ADC LoadCell3(LOADCELL3_DOUT_PIN, LOADCELL3_SCK_PIN);
HX711_ADC LoadCell4(LOADCELL4_DOUT_PIN, LOADCELL4_SCK_PIN);

// Perturbation array - define your perturbation sizes here
const float perturbations[] = {0.6};          
const int numPerturbations = sizeof(perturbations) / sizeof(perturbations[0]);

// Control variables
float targetTension1 = 0, targetTension2 = 0, targetTension3 = 0, targetTension4 = 0;
float baseTension1, baseTension2, baseTension3;  // Store original targets
const int STEP_DELAY = 1000;
const float TOLERANCE = 0.03;
const float ZERO_TOLERANCE = 0.05;
bool returningToZero = false;

// Perturbation state variables
bool motor4Frozen = false;
int perturbationIndex = 0;  // Current perturbation (0 to numPerturbations-1)
int motorIndex = 0;  // Current motor (0=motor1, 1=motor2, 2=motor3)

void setup() {
  Serial.begin(115200);
  Serial.println("Tension Control System Starting...");
  
  setupMotors();
  setupLoadCells();
  getUserTargets();
  
  Serial.println("System ready. Motors will adjust to target tensions.");
  Serial.println("Send 's' to start perturbation sequence.");
  Serial.println("Send 'c' anytime to cancel and set tensions to zero.");
}

void loop() {
  // Check for commands
  if (Serial.available() > 0) {
    char command = Serial.read();
    
    // Handle 's' command - perturbation sequence
    if (command == 's' || command == 'S') {
      if (!motor4Frozen) {
        // First 's' press: freeze motor 4 and start perturbation sequence
        motor4Frozen = true;
        baseTension1 = targetTension1;
        baseTension2 = targetTension2;
        baseTension3 = targetTension3;
        perturbationIndex = 0;
        motorIndex = 0;
        targetTension1 = baseTension1 + perturbations[0];
        Serial.print("Motor 4 frozen. Perturbation "); Serial.print(perturbations[0], 2);
        Serial.println(" applied to Motor 1.");
        Serial.print("New targets: M1="); Serial.print(targetTension1, 2);
        Serial.print(" M2="); Serial.print(targetTension2, 2);
        Serial.print(" M3="); Serial.println(targetTension3, 2);
      } else {
        // Remove perturbation from current motor before moving on
        if (motorIndex == 0) {
          targetTension1 = baseTension1;
          Serial.print("Perturbation removed from Motor 1. M1=");
          Serial.println(targetTension1, 2);
        } else if (motorIndex == 1) {
          targetTension2 = baseTension2;
          Serial.print("Perturbation removed from Motor 2. M2=");
          Serial.println(targetTension2, 2);
        } else if (motorIndex == 2) {
          targetTension3 = baseTension3;
          Serial.print("Perturbation removed from Motor 3. M3=");
          Serial.println(targetTension3, 2);
        }
        
        // Move to next motor
        motorIndex++;
        
        if (motorIndex > 2) {
          // Finished all 3 motors for current perturbation, move to next
          motorIndex = 0;
          perturbationIndex++;
          
          if (perturbationIndex >= numPerturbations) {
            // All perturbations complete - act like 'c'
            targetTension1 = 0;
            targetTension2 = 0;
            targetTension3 = 0;
            targetTension4 = 0;
            motor4Frozen = false;
            returningToZero = true;
            perturbationIndex = 0;
            motorIndex = 0;
            Serial.println("\nAll perturbations complete. Returning to zero.");
            while (Serial.available() > 0) Serial.read();
            return;
          }
        }
        
        // Apply current perturbation to current motor
        if (motorIndex == 0) {
          targetTension1 = baseTension1 + perturbations[perturbationIndex];
          Serial.print("Perturbation "); Serial.print(perturbations[perturbationIndex], 2);
          Serial.println(" applied to Motor 1.");
        } else if (motorIndex == 1) {
          targetTension2 = baseTension2 + perturbations[perturbationIndex];
          Serial.print("Perturbation "); Serial.print(perturbations[perturbationIndex], 2);
          Serial.println(" applied to Motor 2.");
        } else if (motorIndex == 2) {
          targetTension3 = baseTension3 + perturbations[perturbationIndex];
          Serial.print("Perturbation "); Serial.print(perturbations[perturbationIndex], 2);
          Serial.println(" applied to Motor 3.");
        }
        
        Serial.print("New targets: M1="); Serial.print(targetTension1, 2);
        Serial.print(" M2="); Serial.print(targetTension2, 2);
        Serial.print(" M3="); Serial.println(targetTension3, 2);
      }
      while (Serial.available() > 0) Serial.read();
    }
    
    // Handle 'c' command - cancel and reset
    if (command == 'c' || command == 'C') {
      targetTension1 = 0;
      targetTension2 = 0;
      targetTension3 = 0;
      targetTension4 = 0;
      motor4Frozen = false;
      perturbationIndex = 0;
      motorIndex = 0;
      returningToZero = true;
      Serial.println("\nOperation cancelled. Target tensions set to zero.");
      while (Serial.available() > 0) Serial.read();
    }
  }
  
  // Read current tensions
  LoadCell1.update();
  LoadCell2.update();
  LoadCell3.update();
  LoadCell4.update();
  float tension1 = LoadCell1.getData();
  float tension2 = LoadCell2.getData();
  float tension3 = LoadCell3.getData();
  float tension4 = LoadCell4.getData();
  
  // Check if we've reached zero after cancel
  if (returningToZero && 
      abs(tension1) <= ZERO_TOLERANCE && abs(tension2) <= ZERO_TOLERANCE &&
      abs(tension3) <= ZERO_TOLERANCE && abs(tension4) <= ZERO_TOLERANCE) {
    Serial.println("Tensions returned to zero. Ready for new targets.");
    returningToZero = false;
    getUserTargets();
    return;
  }
  
  // Motor 1 control
  float error1 = tension1 - targetTension1;
  if (abs(error1) > TOLERANCE) {
    adjustMicrosteps(1, abs(error1));
    stepMotor(1, error1 < 0);
  }
  
  // Motor 2 control
  float error2 = tension2 - targetTension2;
  if (abs(error2) > TOLERANCE) {
    adjustMicrosteps(2, abs(error2));
    stepMotor(2, error2 < 0);
  }
  
  // Motor 3 control
  float error3 = tension3 - targetTension3;
  if (abs(error3) > TOLERANCE) {
    adjustMicrosteps(3, abs(error3));
    stepMotor(3, error3 < 0);
  }
  
  // Motor 4 control - skip if frozen
  if (!motor4Frozen) {
    float error4 = tension4 - targetTension4;
    if (abs(error4) > TOLERANCE) {
      adjustMicrosteps(4, abs(error4));
      stepMotor(4, error4 < 0);
    }
  }
  
  // Print status
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 100) {
    Serial.print("Tension1:"); Serial.print(tension1, 2); Serial.print(" ");
    Serial.print("Tension2:"); Serial.print(tension2, 2); Serial.print(" ");
    Serial.print("Tension3:"); Serial.print(tension3, 2); Serial.print(" ");
    Serial.print("Tension4:"); Serial.print(tension4, 2); Serial.print(" ");
    Serial.print("Target1:"); Serial.print(targetTension1, 2); Serial.print(" ");
    Serial.print("Target2:"); Serial.print(targetTension2, 2); Serial.print(" ");
    Serial.print("Target3:"); Serial.print(targetTension3, 2); Serial.print(" ");
    Serial.print("Target4:"); Serial.println(targetTension4, 2);
    lastPrint = millis();
  }
  
  delay(30);
}

// Setup motor drivers
void setupMotors() {
  pinMode(MOTOR1_STEP_PIN, OUTPUT); pinMode(MOTOR1_DIR_PIN, OUTPUT); pinMode(MOTOR1_EN_PIN, OUTPUT);
  pinMode(MOTOR2_STEP_PIN, OUTPUT); pinMode(MOTOR2_DIR_PIN, OUTPUT); pinMode(MOTOR2_EN_PIN, OUTPUT);
  pinMode(MOTOR3_STEP_PIN, OUTPUT); pinMode(MOTOR3_DIR_PIN, OUTPUT); pinMode(MOTOR3_EN_PIN, OUTPUT);
  pinMode(MOTOR4_STEP_PIN, OUTPUT); pinMode(MOTOR4_DIR_PIN, OUTPUT); pinMode(MOTOR4_EN_PIN, OUTPUT);
  digitalWrite(MOTOR1_EN_PIN, HIGH);
  digitalWrite(MOTOR2_EN_PIN, HIGH);
  digitalWrite(MOTOR3_EN_PIN, HIGH);
  digitalWrite(MOTOR4_EN_PIN, HIGH);
  
  Serial1.begin(115200);
  delay(10);
  
  driver1.begin();
  driver1.toff(5);
  driver1.I_scale_analog(false);
  driver1.rms_current(1000);
  driver1.en_spreadCycle(false);
  driver1.pwm_autoscale(true);
  driver1.pwm_autograd(true);

  driver2.begin();
  driver2.toff(5);
  driver2.I_scale_analog(false);
  driver2.rms_current(1000);
  driver2.en_spreadCycle(false);
  driver2.pwm_autoscale(true);
  driver2.pwm_autograd(true);

  driver3.begin();
  driver3.toff(5);
  driver3.I_scale_analog(false);
  driver3.rms_current(1000);
  driver3.en_spreadCycle(false);
  driver3.pwm_autoscale(true);
  driver3.pwm_autograd(true);

  driver4.begin();
  driver4.toff(5);
  driver4.I_scale_analog(false);
  driver4.rms_current(1000);
  driver4.en_spreadCycle(false);
  driver4.pwm_autoscale(true);
  driver4.pwm_autograd(true);

  delay(1000);
  digitalWrite(MOTOR1_EN_PIN, LOW);
  digitalWrite(MOTOR2_EN_PIN, LOW);
  digitalWrite(MOTOR3_EN_PIN, LOW);
  digitalWrite(MOTOR4_EN_PIN, LOW);
  
  Serial.println("Motors configured");
}

// Setup load cells
void setupLoadCells() {
  LoadCell1.begin();
  LoadCell2.begin();
  LoadCell3.begin();
  LoadCell4.begin();
  
  unsigned long stabilizingtime = 2000;
  LoadCell1.start(stabilizingtime, true);
  LoadCell2.start(stabilizingtime, true);
  LoadCell3.start(stabilizingtime, true);
  LoadCell4.start(stabilizingtime, true);
  
  LoadCell1.setCalFactor(150000.0);
  LoadCell2.setCalFactor(150000.0);
  LoadCell3.setCalFactor(150000.0);
  LoadCell4.setCalFactor(150000.0);
  
  while (!LoadCell1.update() || !LoadCell2.update() || !LoadCell3.update() || !LoadCell4.update());
  
  Serial.println("Load cells calibrated and ready");
}

// Get target tensions from user
void getUserTargets() {
  while (Serial.available() > 0) Serial.read();
  
  Serial.println("\n--- Set Target Tensions ---");
  
  Serial.print("Enter target tension for Motor 1 (units): ");
  while (!Serial.available());
  targetTension1 = Serial.parseFloat();
  while (Serial.available() > 0) Serial.read();
  Serial.println(targetTension1, 2);
  
  Serial.print("Enter target tension for Motor 2 (units): ");
  while (!Serial.available());
  targetTension2 = Serial.parseFloat();
  while (Serial.available() > 0) Serial.read();
  Serial.println(targetTension2, 2);
  
  Serial.print("Enter target tension for Motor 3 (units): ");
  while (!Serial.available());
  targetTension3 = Serial.parseFloat();
  while (Serial.available() > 0) Serial.read();
  Serial.println(targetTension3, 2);
  
  Serial.print("Enter target tension for Motor 4 (units): ");
  while (!Serial.available());
  targetTension4 = Serial.parseFloat();
  while (Serial.available() > 0) Serial.read();
  Serial.println(targetTension4, 2);
  
  Serial.println("Targets set. Starting tension control...\n");
}

// Adjust microsteps based on distance from target
void adjustMicrosteps(int motorNum, float error) {
  int microsteps;
  
  if (motorNum == 1 || motorNum == 2 || motorNum == 3) {
    if (error > 1.5) {
      microsteps = 8;
    } else if (error > 0.75) {
      microsteps = 8;
    } else if (error > 0.4) {
      microsteps = 16;
    } else if (error > 0.2) {
      microsteps = 64;
    } else if (error > 0.1) {
      microsteps = 256;
    } else if (error > 0.05) {
      microsteps = 256;
    } else {
      microsteps = 256;
    }
  } else if (motorNum == 4) {
    if (returningToZero) {
      microsteps = 8;
    } else if (error > 1.5) {
      microsteps = 2;
    } else if (error > 0.75) {
      microsteps = 2;
    } else if (error > 0.4) {
      microsteps = 2;
    } else if (error > 0.2) {
      microsteps = 8;
    } else if (error > 0.1) {
      microsteps = 32;
    } else if (error > 0.05) {
      microsteps = 128;
    } else {
      microsteps = 256;
    }
  }
  
  if (motorNum == 1) {
    driver1.microsteps(microsteps);
  } else if (motorNum == 2) {
    driver2.microsteps(microsteps);
  } else if (motorNum == 3) {
    driver3.microsteps(microsteps);
  } else {
    driver4.microsteps(microsteps);
  }
}

// Step a single motor
void stepMotor(int motorNum, bool forward) {
  int stepPin, dirPin;
  
  switch(motorNum) {
    case 1:
      stepPin = MOTOR1_STEP_PIN;
      dirPin = MOTOR1_DIR_PIN;
      break;
    case 2:
      stepPin = MOTOR2_STEP_PIN;
      dirPin = MOTOR2_DIR_PIN;
      break;
    case 3:
      stepPin = MOTOR3_STEP_PIN;
      dirPin = MOTOR3_DIR_PIN;
      break;
    case 4:
      stepPin = MOTOR4_STEP_PIN;
      dirPin = MOTOR4_DIR_PIN;
      break;
  }
  
  digitalWrite(dirPin, forward ? LOW : HIGH);
  digitalWrite(stepPin, HIGH);
  delayMicroseconds(2);
  digitalWrite(stepPin, LOW);
  delayMicroseconds(STEP_DELAY);
}