#!/usr/bin/env python3

import argparse
import time
import threading

from aiy.board import Board, Led
from aiy.voice.audio import AudioFormat, play_wav, record_file, Recorder


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--filename", "-f", default="recorded.wav")
    args = parser.parse_args()

    with Board() as board:
        board.led.state = Led.BEACON

        while True:
            print("Press button to play recorded sound.")
            board.button.wait_for_press()

            print("Playing...")
            board.led.state = Led.ON
            play_wav(args.filename)
            board.led.state = Led.BEACON
            print("Done.")


if __name__ == "__main__":
    main()
