#!/usr/bin/env python3

import argparse
import time
import threading

from aiy.board import Board, Led
from aiy.voice.audio import AudioFormat, play_wav, record_file, Recorder


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--filename", "-f", default="~/recording.wav")
    args = parser.parse_args()

    with Board() as board:
        print("Press button to start recording.")
        board.led.state = Led.BEACON
        board.button.wait_for_press()

        done = threading.Event()
        board.led.state = Led.BLINK
        board.button.when_pressed = done.set

        def wait():
            start = time.monotonic()
            while not done.is_set():
                duration = time.monotonic() - start
                print("Recording: %.02f seconds [Press button to stop]" % duration)
                time.sleep(0.5)

        record_file(AudioFormat.CD, filename=args.filename, wait=wait, filetype="wav")

        print("Press button to play recorded sound.")
        board.led.state = Led.BEACON
        board.button.wait_for_press()

        print("Playing...")
        board.led.state = Led.ON
        play_wav(args.filename)
        print("Done.")


if __name__ == "__main__":
    main()
