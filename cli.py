"""Main app `cli` module."""

import argparse
import importlib
import sys
import traceback
from typing import List, Optional


def exception_hook(kind, value, tb):
    """
    Intended to be assigned to sys.exception as a hook.

    Gives programmer opportunity to do something useful with info from uncaught exceptions.

    Arguments:
        kind: Exception type
        value: Exception's value
        tb: Exception's traceback
    """
    # NOTE: because format() is returning a list of string,
    # I'm going to join them into a single string, separating each with a new line
    traceback_details = "\n".join(traceback.extract_tb(tb).format())

    error_msg = (
        "An exception has been raised outside of a try/except!!!\n"
        f"Type: {kind}\n"
        f"Value: {value}\n"
        f"Traceback: {traceback_details}"
    )
    print(error_msg)


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
    # init exception hook
    sys.excepthook = exception_hook

    # init parser
    parser = get_parser()
    opts, appargs = parser.parse_known_args(args=args)

    # import app module
    pkg = importlib.import_module(f"pspark.{opts.app}.cli")
    print(pkg)

    # run app module
    return pkg.main(appargs)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
