#!/usr/bin/env python3

from aiy.board import Board, Led


def main():
    with Board() as board:
        board.led.state = Led.OFF
        print("Done.")


if __name__ == "__main__":
    main()
