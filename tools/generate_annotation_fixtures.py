"""Generate synthetic dictionary fixtures backed by GNU PSPP and its format notes."""
import argparse
from pathlib import Path
import re
import subprocess

from fixture_writer import extension, sav
from pspp_oracle import binary

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    out = parser.parse_args().output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    pspp_file = out / "annotations-pspp.sav"
    commands = """DATA LIST FREE /score wave.
BEGIN DATA
88 1
99 2
END DATA.
ADD DOCUMENT 'Field survey' 'Second line'.
DATAFILE ATTRIBUTE ATTRIBUTE=Project("team's / notes") Stage('one') Stage[2]('two').
VARIABLE ATTRIBUTE VARIABLES=score ATTRIBUTE=Units('points') /VARIABLES=wave ATTRIBUTE=Units('visit').
MRSETS /MCGROUP NAME=$items LABEL='Survey items' VARIABLES=score wave.
"""
    syntax = out / "producer.sps"
    path = str(pspp_file).replace("'", "''")
    syntax.write_text(commands + f"SAVE OUTFILE='{path}' /UNCOMPRESSED.\n", encoding="utf-8")
    subprocess.run([binary(), "--batch", str(syntax)], check=True, timeout=20)
    data = bytearray(pspp_file.read_bytes())
    data[92:109] = b"22 NOV 26" + b"00:00:00"
    # Freeze producer-generated dates while retaining PSPP's source record layout.
    data = re.sub(rb"\(Entered [0-9 ]{2} [A-Za-z]{3} [0-9]{4}\)", b"(Entered 22 Nov 2026)", data)
    pspp_file.write_bytes(data)
    sets = extension(13, b"SCORE=survey_score\tWAVE=wave")
    sets += extension(5, b"Survey= wave survey_score\r\nEmpty= \n")
    (out / "annotations-varsets.sav").write_bytes(sav([{"name": "SCORE"}, {"name": "WAVE"}], [[88., 1.]], extensions=sets))
    mr = extension(7, b"$c=C 6 " + "中文".encode() + b" a b\n$d=D1 1 0  a b\n")
    mr += extension(19, b"$e=E 11 1 0 0  a b\n")
    (out / "annotations-mrsets.sav").write_bytes(sav([{"name": "A"}, {"name": "B"}], [[1., 0.]], extensions=mr))


if __name__ == "__main__":
    main()
