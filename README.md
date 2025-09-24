# Wave Data Loading Toolbox

A MATLAB toolbox for extracting and analysing wave and wind hindcast data from the [CAWCR Wave Hindcast – Aggregated Collection](https://researchdata.edu.au/cawcr-wave-hindcast-aggregated-collection/1401722#:~:text=Organisation%26rft,4%20degree%20%2824%20arcminute), with efficient single‑point loading, optional monthly caching, and basic visualisation.

## Quick start

Loads data for January to December 2015 at a specified location.

```matlab
% Loads wave data
[wave_data, dataset_metadata] = loadWaveData(145.1768, -40.026, 201501, 201512);

% Loads wind data
[wind_data, dataset_metadata] = loadWaveData(145.1768, -40.026, 201501, 201512, 'wind', true);
```

- [Usage Guide](docs/usage.md)
- [Function and Parameter Reference](docs/parameters.md)
-
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Toolbox Structure](docs/structure.md)

## Installation

Download via [Releases](https://github.com/YiTingTsou/wave-data-toolbox/releases) or clone this repository:

```bash
git clone https://github.com/YiTingTsou/wave-data-toolbox.git
cd wave-data-toolbox
```

In MATLAB, add the toolbox to your path:

```matlab
addpath(genpath('path/to/wave-data-toolbox'))

% If want to make this permanent across MATLAB sessions:
savepath
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
- Wave and wind data are downloaded from the CAWCR Wave Hindcast via OPeNDAP
- The complete dataset is saved to `outputs/` in both .mat and .csv formats, along with a metadata file in .mat format
- Probability distribution heatmap and directional wave rose are generated and saved
- A figure confirms that wave and wind data are loaded close to the target location

**Tip:** Load only one month first to verify the selected grid point is close to your target location.

## Requirements

- MATLAB R2024a (tested). Compatibility with earlier versions is not guaranteed.
- Internet connection (for OPeNDAP access)

## Data source and terms

This toolbox accesses the [CAWCR Wave Hindcast – Aggregated Collection](https://researchdata.edu.au/cawcr-wave-hindcast-aggregated-collection/1401722#:~:text=Organisation%26rft,4%20degree%20%2824%20arcminute) via CSIRO's THREDDS services. The collection provides global and nested regional wave hindcast grids updated monthly since 1979.

**Key resources:**

- **Terms and reuse**: See [Collection page](https://data.csiro.au/collection/csiro:39819) for terms of use, acknowledgement, and reuse notes
- **Direct data access (THREDDS)**:
  - Wave data - [gridded](http://data-cbr.csiro.au/thredds/catalog/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/catalog.html)
  - Wind data - [spec](https://data-cbr.csiro.au/thredds/catalog/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/spec/catalog.html)
- **Access guide**: [DAP guide to THREDDS and OPeNDAP access](https://research.csiro.au/dap/download/accessing-data-via-a-thredds-catalogue/)

**Important:** This toolbox accesses data via OPeNDAP for research use. If you plan to redistribute data files, please review the [collection page](https://data.csiro.au/collection/csiro:39819) for current terms and contact information.

## Citation and Acknowledgement

**Data acknowledgement:**

> Source: Bureau of Meteorology and CSIRO © 2013
>
> All Rights (including copyright) Bureau of Meteorology, CSIRO 2019.

**Dataset citation:**

```
Durrant, Thomas ; Hemer, Mark ; Smith, Grant ; Trenham, Claire ; Greenslade, Diana (2020): CAWCR Wave Hindcast - Aggregated Collection. v5. Commonwealth Scientific and Industrial Research Organisation.dataset.
http://hdl.handle.net/102.100.100/137152?index=1
```

**Toolbox citation:**

```
Tsou, Y.-T. (2025). Wave Data Loading Toolbox [Computer software]. Australian Maritime College, University of Tasmania. GitHub. https://github.com/YiTingTsou/wave-data-toolbox
```

## License

- **Code:** MIT License (see [LICENSE](LICENSE)).
- **Data:** Governed by the terms on the CSIRO collection page and the THREDDS services. Do not redistribute data files without checking those terms and contacts.

### Third-Party Components and Licenses

This project includes the following third-party component:

- **customcolormap.m**  
  Copyright (c) 2018, Víctor Martínez-Cagigal  
  See [`BSD_VictorMartinezCagigal`](/third_party_licenses/BSD_VictorMartinezCagigal.txt) for full text.

## Contributing

Issues and pull requests are welcome. Please open an issue for bugs or feature requests.

## Maintainer

Yi‑Ting Tsou  
Australian Maritime College | University of Tasmania  
Email: YiTing.Tsou@utas.edu.au

## Acknowledgements and use of AI tools

Parts of the codebase, including comments and documentation, were developed with the assistance of AI tools for code suggestions, debugging, and refinement. All generated content was reviewed and verified by the author before integration.
