"""Executa Main.qs no simulador local do QDK."""

from pathlib import Path
from qdk import qsharp


if __name__ == "__main__":
    qsharp.init()
    qsharp.eval(Path(__file__).with_name("Main.qs").read_text(encoding="utf-8"))
    qsharp.eval("AD2Grover.Main()")
