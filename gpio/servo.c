#include <stdio.h>
#include <stdlib.h>
#include <softPwm.h>
#include <wiringPi.h>

#define out 0

int main(void)
{
    if (wiringPiSetup() == -1)
    {
        return 1;
    }

    int pos = 10;
    int dir = 5;

    int min = 10;
    int max = 20;

    pinMode(out, OUTPUT);       // 0 pin | GPIO 17
    digitalWrite(out, LOW);     // 0 pin output LOW voltage
    softPwmCreate(out, 0, 200); // 0 pin PWM 20ms

    // 10은 1ms, 15는 1.5ms, 20은 2.0ms,
    // 10은 최저각, 15는 중립, 20은 최고각
    while (1)
    {
        softPwmWrite(out, pos);

        pos += dir;

        if (pos <= min || pos >= max)
        {
            dir *= -1;
        }

        delay(500);
    }

    return 0;
}
