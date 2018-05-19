#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <softPwm.h>

#define out 0

int main (void)
{
    if (wiringPiSetup() == -1) {
        return 1;
    }

    int pos = 10;
    int dir = 5;

    int min = 10;
    int max = 20;

    pinMode(out, OUTPUT); // 0 pin | GPIO 17
    digitalWrite(out, LOW); // 0 pin output LOW voltage
    softPwmCreate(out, 0, 200); // 0 pin PWM 20ms

    softPwmWrite(out, 15);
    delay(500);

    return 0;
}
