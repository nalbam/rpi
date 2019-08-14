#include <stdio.h>
#include <wiringPi.h>

#define trigPin 4
#define echoPin 5

int main(void)
{
    if (wiringPiSetup() == -1)
    {
        return 1;
    }

    pinMode(trigPin, OUTPUT);
    pinMode(echoPin, INPUT);

    FILE *fp;

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

        fp = fopen("distance", "w");
        fprintf(fp, "{\"distance\":\"%d\"}\n", distance);
        fclose(fp);

        delay(500);
    }

    return 0;
}
