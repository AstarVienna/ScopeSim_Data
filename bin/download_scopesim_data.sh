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
  rm -r "${DIR_WORK}"
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
# All poetry files are updated with `poetry update` to ensure we test the latest
# versions of our dependencies.

# Pyckles must go first, because otherwise it uninstalls scipy (????). See
# https://stackoverflow.com/questions/67085976/how-to-stop-poetry-from-uninstalling-packages
git clone https://github.com/AstarVienna/Pyckles.git
pushd Pyckles
poetry install --with=test,docs
poetry update --with=test,docs
popd

git clone https://github.com/AstarVienna/speXtra.git
pushd speXtra
poetry install --with=test,docs
poetry update --with=test,docs
popd

git clone https://github.com/AstarVienna/ScopeSim.git
pushd ScopeSim
poetry install --with=test,dev,docs
poetry update --with=test,dev,docs
popd

git clone https://github.com/AstarVienna/skycalc_ipy.git
pushd skycalc_ipy
poetry install --with=test,docs
poetry update --with=test,docs
popd

git clone https://github.com/AstarVienna/AnisoCADO.git
pushd AnisoCADO
# AnisoCADO doesn't use poetry yet.
pip install -e ".[test,dev,docs]"
popd

git clone https://github.com/AstarVienna/ScopeSim_Templates.git
pushd ScopeSim_Templates
poetry install --with=test,dev,docs
poetry update --with=test,dev,docs
popd

git clone https://github.com/AstarVienna/irdb.git
pushd irdb
# irdb doesn't use poetry yet
pip install -e ".[test]"
popd

# poetry update will upgrade only to the latest versions that are released.
# The packages will therefore downgrade each other.
# But ScopeSim_Data should use the latest version of all our projects
# (to download the data they need, and to test whether they work together).
# So the projects need to be installed again.
# Note that it is not possible to only use pip, poetry is required to install
# the dependency groups (that is, dev/test/docs). See
# https://stackoverflow.com/questions/76118614/is-it-possible-to-install-poetry-groups-with-pip
pip install -e Pyckles
pip install -e speXtra
pip install -e ScopeSim
pip install -e ScopeSim_Templates
pip install -e skycalc_ipy
pip install -e AnisoCADO
pip install -e irdb


# Run the tests.
pushd Pyckles
python -m pytest
popd

pushd speXtra
python -m pytest
popd

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
