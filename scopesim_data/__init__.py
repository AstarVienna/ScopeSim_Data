# -*- coding: utf-8 -*-
"""Cache paths are defined here."""

from pathlib import Path

path_here = Path(__file__).parent

cache_dir = path_here / "data"

__all__ = ["cache_dir"]
