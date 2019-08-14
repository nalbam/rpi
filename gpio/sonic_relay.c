#include <stdio.h>
#include <wiringPi.h>

#define trigPin 4
#define echoPin 5

#define out1 2
#define out2 3

int main(void)
{
    if (wiringPiSetup() == -1)
    {
        return 1;
    }

    FILE *fp;

    pinMode(trigPin, OUTPUT);
    pinMode(echoPin, INPUT);

    pinMode(out1, OUTPUT);
    pinMode(out2, OUTPUT);

    int inCount = 0;
    int outCount = 0;
    int delayCount = 5;

    int minDist = 2;
    int maxDist = 350;

    int pos = 70;

    while (1)
    {
        digitalWrite(trigPin, LOW);
        usleep(2);
        digitalWrite(trigPin, HIGH);
        usleep(20);
        digitalWrite(trigPin, LOW);

        while (digitalRead(echoPin) == LOW)
            continue;
        long startTime = micros();

        while (digitalRead(echoPin) == HIGH)
            continue;
        long travelTime = micros() - startTime;

        int distance = travelTime / 58;

        printf("Distance: %dcm\n", distance);

        if (distance > minDist && distance < maxDist)
        {
            if (distance > pos)
            {
                outCount++;
                inCount = 0;

                if (outCount > delayCount)
                {
                    digitalWrite(out1, HIGH);
                    digitalWrite(out2, HIGH);
                }
            }
            else
            {
                inCount++;
                outCount = 0;

                if (inCount > delayCount)
                {
                    digitalWrite(out1, LOW);
                    digitalWrite(out2, LOW);
                }
            }
        }

        fp = fopen("distance", "w");
        fprintf(fp, "{\"distance\":\"%d\"}\n", distance);
        fclose(fp);

        delay(500);
    }

    return 0;
}
