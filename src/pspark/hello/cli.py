"""
Module that contains hello cmd line application.

Can be called with python src/hello/cli.py
"""

import argparse
import logging
from typing import List, Optional

from pyspark.sql import SparkSession
from wonderwords import RandomWord


def get_parser() -> argparse.ArgumentParser:
    """
    Return the CLI argument parser.

    Returns:
        An argparse parser.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=False, type=str, help="input bucket", default="input")
    parser.add_argument("--output", required=False, type=str, help="output bucket", default="output")

    return parser


def init_spark():
    """
    Initialize spark session.

    Returns:
        A spark session.
    """
    rw = RandomWord()

    return SparkSession.builder.appName(f"HelloWorld {rw.word()}").getOrCreate()


def main(args: Optional[List[str]] = None) -> int:
    """
    Run the main program.

    Arguments:
        args: Arguments passed from the command line.

    Returns:
        An exit code.
    """
    # init parser
    parser = get_parser()
    opts = parser.parse_args(args=args)

    session = init_spark()
    sc = session.sparkContext

    # get logger
    logger = logging.getLogger("py4j")
    logger.setLevel(logging.INFO)
    logger.addHandler(logging.StreamHandler())

    logger.info(f"ApplicationId:  {sc.applicationId}, args: {opts}")

    # run app
    nums = sc.parallelize([1, 2, 3, 4])
    logger.info(nums.map(lambda num: num * num).collect())
    print(nums.map(lambda num: num * num).collect())  # kept for tests

    return 0


if __name__ == "__main__":
    main()
