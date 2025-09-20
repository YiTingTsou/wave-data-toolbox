# Wave Data Loading Toolbox

A MATLAB toolbox for extracting and analysing wave hindcast data from the CSIRO/CAWCR Wave Hindcast collection, with fast single‑point loading, optional monthly caching, and basic visualisation.

## Quick start

Loads data for January to December 2015 at a specified location.

```matlab
wave_data = loadWaveData(145.1768, -40.026, 201501, 201512);
summary(wave_data);
```

- [Usage Guide](docs/usage.md)
- [Function and Parameter Reference](docs/parameters.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Toolbox Structure](docs/structure.md)

## Installation

Download via [Releases](https://github.com/YiTingTsou/wave-data-toolbox/releases) or clone this repository:

```bash
git clone https://github.com/YiTingTsou/wave-data-toolbox.git
cd wave-data-toolbox
```

## Features

- Automated OPeNDAP downloads with file‑existence checks
- Spatial subsetting and efficient single-point extraction (avoids loading entire grid data)
- Flexible parameter selection (for example, `hs`, `t02`, `dir`, plus optional extras)
- Optional monthly saving for resume capability and lower memory use
- Built‑in analyses: probability distributions and wave roses

## Usage

Open `loadWaveDataMain.m` and define the latitude, longitude, and time range you want to load.

For detailed function parameters and output descriptions, see the [Usage Guide](docs/usage.md).

### What happens when you run it

- The command window displays the target location and closest available grid point, plus distance between them
- Wave data is downloaded from the CAWCR Wave Hindcast via OPeNDAP
- Complete dataset is saved to `output/` (`wave_data` in .mat and .csv; `dataset_metadata` in .mat only)
- Probability distribution heatmap and directional wave rose are generated and saved

**Tip:** Load only one month first to verify the selected grid point is close to your target location.

## Requirements

- MATLAB R2024a (tested). Compatibility with earlier versions is not guaranteed.
- Internet connection (for OPeNDAP access)

## Data source and terms

This toolbox accesses the **CAWCR Wave Hindcast – Aggregated Collection** via CSIRO's THREDDS services. The collection provides global and nested regional wave hindcast grids updated monthly since 1979.

**Key resources:**

- [Collection page](https://data.csiro.au/collection/csiro:39819) - terms, acknowledgement, and reuse notes
- [THREDDS catalog](http://data-cbr.csiro.au/thredds/catalog/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/catalog.html) - direct data access
- [DAP guide to THREDDS and OPeNDAP access](https://research.csiro.au/dap/download/accessing-data-via-a-thredds-catalogue/) - how‑to for browsing THREDDS catalogs and constructing OPeNDAP URLs

**Important:** This toolbox accesses data via OPeNDAP for research use. If you plan to redistribute data files, please review the [collection page](https://data.csiro.au/collection/csiro:39819) for current terms and contact information.

## Citation and Acknowledgement

**Required data acknowledgement (as specified by CSIRO):**

> Source: Bureau of Meteorology and CSIRO © 2013
>
> All Rights (including copyright) Bureau of Meteorology, CSIRO 2019.

**Dataset citation:**

```
Durrant, Thomas; Hemer, Mark; Smith, Grant; Trenham, Claire; & Greenslade, Diana (2019): CAWCR Wave Hindcast - Aggregated Collection. v5. CSIRO. Service Collection. http://hdl.handle.net/102.100.100/137152?index=1
```

**Toolbox citation:**

```
Tsou, Y.-T. (2025). Wave Data Loading Toolbox [Computer software]. Australian Maritime College, University of Tasmania. GitHub. https://github.com/YiTingTsou/wave-data-toolbox
```

## License

- **Code:** MIT License (see `LICENSE`).
- **Data:** Governed by the terms on the CSIRO collection page and the THREDDS services. Do not redistribute data files without checking those terms and contacts.

### Third-Party Components and Licenses

This project includes the following third-party component:

- **customcolormap.m**  
  Copyright (c) 2018, Víctor Martínez-Cagigal  
  Licensed under the BSD 3-Clause License.  
  See `third_party_licenses/BSD_VictorMartinezCagigal.txt` for full text.

## Contributing

Issues and pull requests are welcome. Please open an issue for bugs or feature requests.

## Maintainer

Yi‑Ting Tsou  
Australian Maritime College | University of Tasmania  
Email: YiTing.Tsou@utas.edu.au

## Acknowledgements and use of AI tools

Some text, code comments, and code suggestions were generated using AI tools and subsequently reviewed and validated by the author. Responsibility for the final content remains with the author.
