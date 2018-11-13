#include <stdio.h>
#include <wiringPi.h>

#define out1 2
#define out2 3

int main(void)
{
    if (wiringPiSetup() == -1)
    {
        return 1;
    }

    pinMode(out1, OUTPUT);
    pinMode(out2, OUTPUT);

    digitalWrite(out1, HIGH);
    digitalWrite(out2, HIGH);

    return 0;
}
