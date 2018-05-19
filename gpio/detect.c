#include <stdio.h>
#include <wiringPi.h>

#define in1 1
#define in2 2
#define out 0

int main (void)
{
    if (wiringPiSetup () == -1) {
        return 1;
    }

    int pos = 10;
    int dir = 5;

    int min = 10;
    int max = 20;

    pinMode(in1, INPUT);
    pinMode(in2, INPUT);

    pinMode(out, OUTPUT);
    digitalWrite(out, LOW);
    softPwmCreate(out, 0, 200); // 20ms

    while (1) {
        long time = micros();

        int read1 = digitalRead(in1);
        int read2 = digitalRead(in2);

        if (read1 == 0 || read2 == 1) {
            printf("Detection. %d\n", time);

            //softPwmWrite(out, pos);

            pos += dir;

            if (pos <= min || pos >= max) {
                dir *= -1;
            }
        } else {
            printf("Not Detected. %d\n", time);
        }

        delay(1000);
    }

    return 0;
}
