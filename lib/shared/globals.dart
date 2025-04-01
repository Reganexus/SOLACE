// Global Variables
bool autoLoginenabled = false;
bool emailVerificationEnabled = true;
int maxExtremeScale = 7; // what will be considered high or True in 0-10 range sliders
int maxNormalScale = 4; // what will be considered normal in 0-10 range sliders

// beats per minute (Heart Rate)
int minPossibleHeartRate = 20;   // Near-death, rare survival
int minExtremeHeartRate = 30;    // Severe bradycardia, medical emergency
int minNormalHeartRate = 60;     // Typical lower bound of normal resting
int maxNormalHeartRate = 100;    // Upper bound of normal resting
int maxExtremeHeartRate = 220;   // Near maximum for exertion (220 - age)
int maxPossibleHeartRate = 300;  // Fatal arrhythmias occur

// mmHg (Blood Pressure - Systolic)
int minPossibleBloodPressureSystolic = 40;   // Circulatory collapse
int minExtremeBloodPressureSystolic = 60;   // Severe hypotension (shock)
int minNormalBloodPressureSystolic = 90;    // Lower bound of normal
int maxNormalBloodPressureSystolic = 130;   // High-normal upper bound
int maxExtremeBloodPressureSystolic = 180;  // Hypertensive emergency
int maxPossibleBloodPressureSystolic = 300; // Lethal hypertensive crisis

// mmHg (Blood Pressure - Diastolic)
int minPossibleBloodPressureDiastolic = 20;  // Severe shock, organ failure
int minExtremeBloodPressureDiastolic = 40;  // Dangerously low
int minNormalBloodPressureDiastolic = 60;   // Lower bound of normal
int maxNormalBloodPressureDiastolic = 80;   // Healthy upper bound
int maxExtremeBloodPressureDiastolic = 120; // Hypertensive emergency
int maxPossibleBloodPressureDiastolic = 200;// Near-fatal pressure

// percentage (Blood Oxygen Saturation - SpO₂)
double minPossibleOxygenSaturation = 30.0;  // Severe hypoxia, near death
double minExtremeOxygenSaturation = 70.0;  // Severe respiratory distress
double minNormalOxygenSaturation = 95.0;   // Lower bound of normal
double maxPossibleOxygenSaturation = 100.0;// Cannot exceed 100 naturally

// breaths per minute (Respiration Rate)
int minPossibleRespirationRate = 4;   // Near respiratory failure
int minExtremeRespirationRate = 8;    // Severe respiratory depression
int minNormalRespirationRate = 12;    // Lower bound of normal
int maxNormalRespirationRate = 20;    // Upper bound of normal
int maxExtremeRespirationRate = 40;   // Severe respiratory distress
int maxPossibleRespirationRate = 80;  // Hyperventilation crisis

// celsius (Body Temperature)
double minPossibleTemperature = 13.0;  // Deep hypothermia, rare survival
double minExtremeTemperature = 28.0;   // Severe hypothermia, likely fatal
double minNormalTemperature = 36.5;    // Normal lower bound
double maxNormalTemperature = 37.2;    // Normal upper bound
double maxExtremeTemperature = 41.0;   // Severe hyperthermia, life-threatening
double maxPossibleTemperature = 47.0;  // Fatal temperature threshold
