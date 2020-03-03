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

```text
GPIO. 0 : servo
GPIO. 1 : ray
GPIO. 2 : touch
GPIO. 4 : triger
GPIO. 5 : echo
GPIO. 6 : temp
```

![GPIO](images/GPIO-Pinout-Diagram-2.png)

## gcc

```bash
gcc -o sonic sonic.c -lwiringPi
```
