"""
Module that contains hello cmd line application.

Can be called with python src/hello/cli.py
"""

from typing import List, Optional

from pyspark.sql import SparkSession
from wonderwords import RandomWord


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
    session = init_spark()
    sc = session.sparkContext

    nums = sc.parallelize([1, 2, 3, 4])
    print(nums.map(lambda num: num * num).collect())

    return 0


if __name__ == "__main__":
    main()
