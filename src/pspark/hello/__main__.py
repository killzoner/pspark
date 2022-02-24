"""
Entry-point module, in case you use `python -m hello`.

Why does this file exist, and why `__main__`? For more info, read:

- https://www.python.org/dev/peps/pep-0338/
- https://docs.python.org/3/using/cmdline.html#cmdoption-m

Can be called with python src/hello/__main__.py
"""

import sys

from cli import main

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
