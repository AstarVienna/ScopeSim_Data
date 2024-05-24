#!/usr/bin/env bash

# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail



# Setup temporary directory. https://stackoverflow.com/a/34676160/2097

# The temp directory used.
DIR_WORK=$(mktemp -d)

# check if tmp dir was created
if [[ ! "${DIR_WORK}" || ! -d "${DIR_WORK}" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

# deletes the temp directory
function cleanup {
  # This requires --force because there are .git directories
  # that have read-only files in them.
  rm -rf "${DIR_WORK}"
  echo "Deleted temp working directory ${DIR_WORK}"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT




if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [data directory]"
  exit 2
fi

if [[ $# -lt 2 ]]; then
  DIR_DATA=$(python -c "from scopesim_data import dir_cache; print(dir_cache)")
  DIR_DATA_SKYCALC=$(python -c "from scopesim_data import dir_cache_skycalc; print(dir_cache_skycalc)")
else
  DIR_DATA=$1
  DIR_DATA_SKYCALC="${DIR_DATA}/skycalc_ipy"
fi

function liberate_dependencies {
  # Replace all ^ dependencies with >= so we test whether the software
  # in the ScopeSim ecosystem works with the latest dependencies of each
  # package. For example, we might have astropy = ^5.3.4 listed while
  # 6.x.y is already out. Changing this here ensures we run at least one
  # test with the most up to date dependencies.
  # The Python version is kept at e.g. ^3.9 because otherwise poetry update
  # will try (and fail) to find a solution for Python 4 as well.
  sed -i 's/ = "^/ = ">=/g;s/python = ">=/python = "^/g' pyproject.toml
  poetry update
}


# Get the right directories.
mkdir -p "${DIR_WORK}"
mkdir -p "${DIR_DATA}"
mkdir -p "${DIR_DATA_SKYCALC}"

export SKYCALC_IPY_CACHE_DIR="${DIR_DATA_SKYCALC}"


# Create the environment.
pushd "${DIR_WORK}"
python -m venv envdata
source envdata/bin/activate
pip install poetry

# Download and install all the packages. Has to be done from git, because the
# releases do not (always) have the test files.
# TODO: Add speXtra and Pickles?

git clone https://github.com/AstarVienna/astar-utils.git
pushd astar-utils
liberate_dependencies
poetry install --with=test
popd

git clone https://github.com/AstarVienna/skycalc_ipy.git
pushd skycalc_ipy
liberate_dependencies
poetry install --with=test,docs
popd

git clone https://github.com/AstarVienna/AnisoCADO.git
pushd AnisoCADO
# AnisoCADO doesn't use poetry yet.
pip install -e ".[test,dev,docs]"
popd

git clone https://github.com/AstarVienna/ScopeSim_Templates.git
pushd ScopeSim_Templates
# ScopeSim_Templates doesn't use poetry yet.
pip install -e ".[test,dev,docs]"
popd

git clone https://github.com/AstarVienna/ScopeSim.git
pushd ScopeSim
liberate_dependencies
poetry install --with=test,dev,docs
popd

git clone https://github.com/AstarVienna/irdb.git
pushd irdb
# irdb doesn't use poetry yet
pip install -e ".[test]"
popd


# Print debug info.
python -c "import scopesim; scopesim.bug_report()"


# Run the tests.
pushd skycalc_ipy
python -m pytest
popd

pushd AnisoCADO
python -m pytest
popd

pushd ScopeSim_Templates
python -m pytest
popd

pushd ScopeSim
python -m pytest
bash ./runnotebooks.sh
popd

pushd irdb
python -m pytest
# TODO: Refactor running IRDB notebooks into separate file.
for fn in METIS/docs/example_notebooks/*.ipynb; do echo "${fn}"; /usr/bin/time -v jupytext --execute --update "${fn}"; done
for fn in METIS/docs/example_notebooks/demos/*.ipynb; do echo "${fn}"; /usr/bin/time -v jupytext --execute --update "${fn}"; done
sed -i "s/USE_FULL_DETECTOR = True/USE_FULL_DETECTOR = False/g" MICADO/docs/example_notebooks/*.ipynb
sed -i 's/# cmd\[\\"!SIM.spectral.spectral_bin_width/cmd\[\\"!SIM.spectral.spectral_bin_width/g' MICADO/docs/example_notebooks/*.ipynb
for fn in MICADO/docs/example_notebooks/*.ipynb; do echo "${fn}"; /usr/bin/time -v jupytext --execute --update "${fn}"; done
popd


# Leave DIR_WORK
popd
