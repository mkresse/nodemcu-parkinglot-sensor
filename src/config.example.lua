WLAN_SSID="my-ssid"
WLAN_PASS="secret"

MQTT_CLIENTID="client1"
MQTT_TOPICID="s1"
MQTT_SERVER="192.168.1.127"
MQTT_PORT=1883

-- Dauer des Deepsleep in s
SLEEP_TIME = 120

-- Checkin-Interval in s
CHECKIN_TIME = 3600

-- Address: successful wlan sample count
RTC_POS_SUCC_SAMPLE_COUNT = 122

-- Address: successful wlan CHECKIN count
RTC_POS_SUCC_CHECKIN_COUNT = 123

-- Address: error count
RTC_POS_ERR_COUNT = 124

-- Address: successfully initialized?
RTC_POS_INITIALIZED = 125

-- Adresse: wann soll der nächste Checkin durchgeführt werden
RTC_POS_NEXT_CHECKIN = 126

--  Adresse für Speicherung des Wertes
RTC_POS_VALUE = 127

TAKEN_THRESHOLD = 2

-- Parking lot is free
PL_FREE = 0

-- Parking lot is occupied
PL_TAKEN = 1

-- State of parking lot is undefined
PL_UNDEFINED = -1
