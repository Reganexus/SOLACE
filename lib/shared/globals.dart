// Global Variables
bool autoLoginenabled = true;
bool emailVerificationEnabled = true;
int maxScale = 7; // what will be considered high or True in 0-10 range sliders

// beats per minute
double maxHeartRate = 100;
double minHeartRate = 60;

// mmHg
double lowBloodPressureSystolic = 90.0;
double normalBloodPressureSystolic = 120.0;

double lowBloodPressureDiastolic = 60.0;
double normalBloodPressureDiastolic = 80.0;


// percentage
double minOxygenSaturation = 92.0;

// breaths per minute
int maxRespirationRate = 20;
int minRespirationRate = 12;

// celsius
double maxTemperature = 38.0;
double minTemperature = 36.0;

// mg/dL
double lowCholesterol = 125;
double normalCholesterol = 200;
double highCholesterol = 240;

// microphone session options
const bool onDevice = true;
const bool cancelOnError = true;
const bool partialResults = true;
const bool autoPunctuation = false;
const bool enableHapticFeedback = true;
const bool debugLogging = false;
const bool logEvents = false;
const int listenFor = 30;
const int pauseFor = 3;
const String localeId = '';