"""Main app `cli` module."""

import argparse
import importlib
import sys
from typing import List, Optional


def get_parser() -> argparse.ArgumentParser:
    """
    Return the CLI argument parser.

    Returns:
        An argparse parser.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--app", required=True, type=str, help="app to run")

    return parser


def main(args: Optional[List[str]] = None) -> int:
    """
    Run the module passed in argument.

    Arguments:
        args: Arguments passed from the command line.

    Returns:
        An exit code.
    """
    parser = get_parser()
    opts, appargs = parser.parse_known_args(args=args)

    pkg = importlib.import_module(f"pspark.{opts.app}.cli")
    print(pkg)

    return pkg.main(appargs)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
