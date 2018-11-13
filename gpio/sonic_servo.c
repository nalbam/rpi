#include <stdio.h>
#include <stdlib.h>
#include <softPwm.h>
#include <wiringPi.h>

#define trigPin 4
#define echoPin 5

#define out 0

int main(void)
{
    if (wiringPiSetup() == -1)
    {
        return 1;
    }

    // 10은 최저각, 15는 중립, 20은 최고각
    int min = 13;
    int max = 17;

    pinMode(trigPin, OUTPUT);
    pinMode(echoPin, INPUT);

    pinMode(out, OUTPUT);       // 0 pin | GPIO 17
    digitalWrite(out, LOW);     // 0 pin output LOW voltage
    softPwmCreate(out, 0, 200); // 0 pin PWM 20ms

    while (1)
    {
        digitalWrite(trigPin, LOW);
        usleep(2);
        digitalWrite(trigPin, HIGH);
        usleep(20);
        digitalWrite(trigPin, LOW);

        while (digitalRead(echoPin) == LOW)
            ;
        long startTime = micros();
        while (digitalRead(echoPin) == HIGH)
            ;
        long travelTime = micros() - startTime;

        int distance = travelTime / 58;

        printf("Distance: %dcm\n", distance);

        if (distance < 30)
        {
            softPwmWrite(out, min);
            delay(300);
            softPwmWrite(out, max);
        }

        delay(500);
    }

    return 0;
}
