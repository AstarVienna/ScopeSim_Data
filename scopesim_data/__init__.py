from pathlib import Path

path_here = Path(__file__).parent

dir_scopesim_cache = path_here.parent / "data"

__all__ = [
    dir_scopesim_cache
]
