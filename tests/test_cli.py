"""Tests for the `cli` module."""

import pytest

from pspark.hello import cli


def test_main():
    """Basic CLI test."""
    assert cli.main([]) == 0


def test_show_help(capsys):
    """
    Show help.

    Arguments:
        capsys: Pytest fixture to capture output.
    """
    try:
        cli.main([])
        # raise ValueError('A very specific bad thing happened')
    except ValueError as err:
        pytest.fail(repr(err))
    captured = capsys.readouterr()
    assert "[1, 4, 9, 16]" in captured.out
