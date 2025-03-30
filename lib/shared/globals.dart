// Global Variables
bool autoLoginenabled = false;
bool emailVerificationEnabled = true;
int maxScale = 7; // what will be considered high or True in 0-10 range sliders

// beats per minute (Heart Rate)
double minPossibleHeartRate = 20;   // Near-death, rare survival
double minExtremeHeartRate = 30;    // Severe bradycardia, medical emergency
double minNormalHeartRate = 60;     // Typical lower bound of normal resting
double maxNormalHeartRate = 100;    // Upper bound of normal resting
double maxExtremeHeartRate = 220;   // Near maximum for exertion (220 - age)
double maxPossibleHeartRate = 300;  // Fatal arrhythmias occur

// mmHg (Blood Pressure - Systolic)
double minPossibleBloodPressureSystolic = 40.0;   // Circulatory collapse
double minExtremeBloodPressureSystolic = 60.0;   // Severe hypotension (shock)
double minNormalBloodPressureSystolic = 90.0;    // Lower bound of normal
double maxNormalBloodPressureSystolic = 130.0;   // High-normal upper bound
double maxExtremeBloodPressureSystolic = 180.0;  // Hypertensive emergency
double maxPossibleBloodPressureSystolic = 300.0; // Lethal hypertensive crisis

// mmHg (Blood Pressure - Diastolic)
double minPossibleBloodPressureDiastolic = 20.0;  // Severe shock, organ failure
double minExtremeBloodPressureDiastolic = 40.0;  // Dangerously low
double minNormalBloodPressureDiastolic = 60.0;   // Lower bound of normal
double maxNormalBloodPressureDiastolic = 80.0;   // Healthy upper bound
double maxExtremeBloodPressureDiastolic = 120.0; // Hypertensive emergency
double maxPossibleBloodPressureDiastolic = 200.0;// Near-fatal pressure

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
