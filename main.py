import subprocess
import sys
from pathlib import Path


def main() -> int:
    base_dir = Path(__file__).resolve().parent
    script_path = base_dir / "main.ps1"

    if not script_path.exists():
        print(f"main.ps1 not found: {script_path}", file=sys.stderr)
        return 1

    command = [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(script_path),
        *sys.argv[1:],
    ]

    completed = subprocess.run(command, cwd=base_dir)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
