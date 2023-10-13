# rpi

## wifi

```bash
sudo vi /etc/wpa_supplicant/wpa_supplicant.conf

network={
  ssid="SSID"
  psk="PASSWORD"
}
```

## run

```bash
git clone https://github.com/nalbam/rpi
./rpi/run.sh auto
```

## gpio

![GPIO](images/GPIO-Pinout-Diagram-2.png)

```text
GPIO. 0 : servo
GPIO. 1 : ray
GPIO. 2 : touch
GPIO. 4 : triger
GPIO. 5 : echo
GPIO. 6 : temp
```

```text
VCC 3V : 1, 17
GND    : 6, 9, 14, 20, 25, 30, 34, 39
DOUT   : 11, 13
```

## gcc

```bash
gcc -o sonic sonic.c -lwiringPi
```
