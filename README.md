# Wave Data Loading Toolbox

A MATLAB toolbox for extracting and analysing wave hindcast data from the CSIRO/CAWCR Wave Hindcast collection, with fast single‑point loading, optional monthly caching, and basic visualisation.

## Quick start

Loads data for January to December 2015 at a specified location.

```matlab
wave_data = loadWaveData(145.1768, -40.026, 201501, 201512);
summary(wave_data);
```

- Detailed usage, options and troubleshooting are in **docs**:
  - `docs/usage.md`
  - `docs/parameters.md`
  - `docs/troubleshooting.md`
  - `docs/structure.md`

## Installation

Download or clone this repository

## Features

- Automated OPeNDAP downloads with file‑existence checks
- Spatial subsetting and nearest valid ocean grid selection
- Flexible parameter selection (for example, `hs`, `t02`, `dir`, plus optional extras)
- Optional monthly saving for resume capability and lower memory use
- Built‑in analyses: probability distributions and wave roses
- Writes a complete dataset to `OutputData/` (`.mat` and `.csv`)
- Efficient single-point extraction instead of loading the entire grid data

## Usage

Open `LoadWaveData_Main.m` and define the latitude, longitude, and time range you want to load.

### Output

- The command window will display the target location and the closest available grid point, along with the distance between them.
- It is recommended to load only one month of data first to verify that the selected grid point is close to your target location.
- The toolbox will then:
  - Download wave data from the CAWCR Wave Hindcast – Aggregated Collection via OPeNDAP.
  - Save the data in both `.mat` and `.csv` formats in the `OutputData/` folder.
  - Generate a probability distribution heatmap and a directional wave rose for the loaded dataset.

## Requirements

- MATLAB R2024a (tested). Compatibility with earlier versions is not guaranteed.
- Internet connection (for OPeNDAP access)

## Data source and terms

This toolbox accesses the **CAWCR Wave Hindcast – Aggregated Collection** via CSIRO’s Data Access Portal and THREDDS services (OPeNDAP, HTTP, WMS/WCS, NetCDF Subset Service). The collection is updated monthly and provides global and nested regional grids since 1979. See the collection page and the THREDDS catalogue for details.

- Collection page: <https://data.csiro.au/collection/csiro:39819>
- THREDDS (gridded): <http://data-cbr.csiro.au/thredds/catalog/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/catalog.html>
- DAP guide to THREDDS and OPeNDAP access: <https://research.csiro.au/dap/download/accessing-data-via-a-thredds-catalogue/>
  **Required acknowledgement (as specified by CSIRO):**
  > Source: Bureau of Meteorology and CSIRO © 2013

Please review the collection page for current terms. It notes the acknowledgement requirement and places restrictions on reproducing or supplying the data files themselves. The metadata and services are publicly accessible; programmatic access via OPeNDAP is supported (this toolbox uses that mode). If you plan to redistribute data files, check the collection page and contact CSIRO/Bureau contacts listed there.

- Collection page details including acknowledgement and reuse notes: <https://data.csiro.au/collection/csiro:39819>
- DAP access methods (OPeNDAP, THREDDS): <https://research.csiro.au/slrwavescoast/waves/data-access/>

## Citation

If you use this toolbox, please cite:

```
Tsou, Y.-T. (2025). Wave Data Loading Toolbox [Computer software]. Australian Maritime College, University of Tasmania. GitHub. https://github.com/YiTingTsou/wave-data-toolbox
```

Please also acknowledge and cite the dataset:

```
Durrant, T., Greenslade, D., Hemer, M., Trenham, C., & Smith, G. (2014).
CAWCR Wave Hindcast – aggregated collection (v1). CSIRO.
https://doi.org/10.4225/08/523168703DCC5
```

## License

- **Code:** MIT License (see `LICENSE`).
- **Data:** Governed by the terms on the CSIRO collection page and the THREDDS services. Do not redistribute data files without checking those terms and contacts.

### Third-Party Components and Licenses

This project includes the following third-party component:

- **[customcolormap].m**  
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
