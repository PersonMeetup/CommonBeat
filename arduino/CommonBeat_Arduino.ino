#define PLR_L 2
#define PLR_R 3

void setup() {
	pinMode(PLR_L, INPUT);
	pinMode(PLR_R, INPUT);
	Serial.begin(9600);
}

void loop() {
	Serial.print(digitalRead(PLR_L));
  Serial.print('\t');
	Serial.println(digitalRead(PLR_R));
	delay(100);
}
