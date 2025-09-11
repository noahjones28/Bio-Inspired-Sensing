/*
  TMC2209 + Mega2560 (Elegoo/Arduino)
  - Uses UART on Serial1 (pins 18/19)
  - Blocking demo: moves forward then back
  - Change R_SENSE and current to match your driver!
*/

#include <TMCStepper.h>

// ===== Pins =====
constexpr uint8_t STEP_PIN = 30;
constexpr uint8_t DIR_PIN  = 40;
constexpr uint8_t EN_PIN   = 50;

// ===== Driver config =====
// Sense resistor: common modules use 0.11 Ω; some use 0.15 Ω (check your board)
constexpr float   R_SENSE = 0.11f;
// Address set by MS1/MS2 (CFG) pins in UART mode; default 0b00
constexpr uint8_t DRIVER_ADDRESS = 0b00;

// Hardware UART on Mega 2560
TMC2209Stepper driver(&Serial1, R_SENSE, DRIVER_ADDRESS);

// ===== Motion params =====
const long STEPS_PER_REV = 200 * 16;     // 1.8° motor * 16 microsteps = 3200
const long TRAVEL_STEPS  = STEPS_PER_REV; // one rev per move
const uint32_t STEP_DELAY_US = 800;      // smaller = faster (e.g., 800 µs ≈ 1250 steps/s)

// ===== Helpers =====
void stepN(long steps, bool dir, uint32_t delay_us_each) {
  digitalWrite(DIR_PIN, dir ? HIGH : LOW);
  for (long i = 0; i < steps; i++) {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(2);           // min high time
    digitalWrite(STEP_PIN, LOW);
    delayMicroseconds(delay_us_each);
  }
}

void configureDriver() {
  // Bring up UART
  Serial1.begin(115200);   // TMC2209 default UART baud (can do 57600–115200)
  delay(10);

  driver.begin();          // init UART
  // Required to enable driver
  pinMode(EN_PIN, OUTPUT);
  digitalWrite(EN_PIN, LOW); // LOW = enabled

  // ===== Core driver tuning =====
  driver.toff(5);              // enable driver, recommended 3–5
  driver.blank_time(24);
  driver.rms_current(900);     // mA RMS (set for your motor/thermal limits)
  driver.microsteps(16);       // 1,2,4,8,16,32,64,128,256
  driver.en_spreadCycle(false);// false = stealthChop (quiet)
  driver.pwm_autoscale(true);  // needed for stealthChop
  driver.pwm_autograd(true);

  // Optional: set TCOOLTHRS if you ever use StallGuard (spreadCycle)
  // driver.TCOOLTHRS(0xFFFF);

  // Optional sanity prints
  Serial.println("TMC2209 configured.");
  Serial.print("DRV_STATUS: 0x"); Serial.println(driver.DRV_STATUS(), HEX);
}

void setup() {
  // USB serial for logs
  Serial.begin(115200);
  while (!Serial) {}  // wait for USB on some boards

  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN,  OUTPUT);
  pinMode(EN_PIN,   OUTPUT);
  digitalWrite(EN_PIN, LOW);   // enable output

  configureDriver();

  Serial.println("Ready. Moving soon...");
  delay(500);
}

void loop() {
  // Forward one revolution
  Serial.println("Forward");
  stepN(TRAVEL_STEPS, /*dir=*/true, STEP_DELAY_US);
  delay(300);

  // Backward one revolution
  Serial.println("Backward");
  stepN(TRAVEL_STEPS, /*dir=*/false, STEP_DELAY_US);
  delay(600);
}
