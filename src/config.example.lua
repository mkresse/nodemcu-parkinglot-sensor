WLAN_SSID="my-ssid"
WLAN_PASS="secret"

MQTT_CLIENTID="client1"
MQTT_TOPICID="s1"
MQTT_SERVER="192.168.1.127"
MQTT_PORT=1883
MQTT_USER="username"
MQTT_PASSWD="password"

-- Global timeout for a whole cycle
GLOBAL_TIMEOUT = 15000

-- Duration of deep sleep in s
SLEEP_TIME = 120

-- Checkin interval in s
CHECKIN_TIME = 3600

-- ADC factor to account for RVDs
ADC_FACTOR = 3.3*2/1024

-- Emit warning if voltage drops below this value
LOW_BATTERY_WARNING_LIMIT = 3.8

-- Enable temperature measurement
MEASURE_TEMPERATURE = TRUE

---- Positions within RTC memory ----

-- successful distance sampling count
RTC_POS_SUCC_SAMPLE_COUNT = 122

-- successful wlan CHECKIN count
RTC_POS_SUCC_CHECKIN_COUNT = 123

-- error count
RTC_POS_ERR_COUNT = 124

-- was successfully initialized?
RTC_POS_INITIALIZED = 125

-- time of the next checkin
RTC_POS_NEXT_CHECKIN = 126

-- state of the parking lot
RTC_POS_VALUE = 127

-- Distances below this value are recognized as occupancy
TAKEN_THRESHOLD = 2


-- Parking lot is free
PL_FREE = 0

-- Parking lot is occupied
PL_TAKEN = 1

-- State of parking lot is undefined
PL_UNDEFINED = -1
