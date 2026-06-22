# -*- coding: utf-8 -*-
"""Suggested scopesim_data/__init__.py to pair with astar_utils.cache_dir.

Changes vs the current version:
* ``dir_cache`` -> ``cache_dir`` (reads more naturally; matches astar-utils).
* Per-package attributes (``dir_cache_skycalc``) are no longer needed:
  astar-utils derives ``cache_dir / <package_name>`` itself. The folder name
  must therefore match the package name used in the call, e.g. ``skycalc_ipy``
  calls ``get_write_cache_dir("skycalc_ipy")`` -> ``data/skycalc_ipy/``.
  (The existing folder is ``data/skycalc_ipy``, so update skycalc_ipy to pass
  "skycalc_ipy" rather than relying on the old ``dir_cache_skycalc`` name.)
* ``__all__`` now holds names (strings), not Path objects.
* Add a ``data/spextra`` (and ``data/spextra/svo``) folder so the bundle can
  serve spextra; ship a ``.keep`` in each as you already do for skycalc_ipy.
"""

from pathlib import Path

path_here = Path(__file__).parent

cache_dir = path_here / "data"

__all__ = ["cache_dir"]
