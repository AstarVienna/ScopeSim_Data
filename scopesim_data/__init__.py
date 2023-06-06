from pathlib import Path

path_here = Path(__file__).parent

dir_cache = path_here / "data"
dir_cache_skycalc = dir_cache / "skycalc_ipy"

__all__ = [
    dir_cache,
    dir_cache_skycalc,
]
