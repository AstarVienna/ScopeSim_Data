# ScopeSim_Data

This repository contains data that is frequently downloaded by ScopeSim and related packages.
The goal of this repository is to make it possible to use ScopeSim without an internet connection, in particular when running tests.

The tests used to fail often (e.g. on github actions) with a timeout error.
It is better to cache the test data, because it uses the same data each time.

Currently, `ScopeSim_Data` contains the data from
* `skycalc_ipy`

that is downloaded by tests or notebooks from
* `ScopeSim`
* `ScopeSim_Templates`
* `irdb`
* `skycalc_ipy`
* `AnisoCADO`

## Usage

`ScopeSim_Data` is a Python package, but there is no PyPI package for it, so it can be installed manually:

```shell
pip install git+https://github.com/AstarVienna/ScopeSim_Data.git
```

Then `skycalc_ipy` will automatically find it and use the cached data.

### Advanced Usage

If you want to cache your own data, you need to install from a local git clone in editable mode:

```shell
git clone https://github.com/AstarVienna/ScopeSim_Data.git
cd ScopeSim_Data
pip install --editable .
```

Then any data you retrieve will be stored in the repository.
Please create a pull request with the data if you believe it is useful for others as well.

## Updating the Cache

The "Download data required by ScopeSim" github action updates the data in this repository.
The action is run every night, and can also be ran manually.

The "Download data" action installs all ScopeSim related packages from source, runs their full tests suites, including notebooks.
It will subsequestly create a pull request with any new data that has been retrieved.

## TODO

There are several other packages that download from the internet, e.g. `speXtra`.
Those could be added to the `ScopeSim_data` repository as well.

