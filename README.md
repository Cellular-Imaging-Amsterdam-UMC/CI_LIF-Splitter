# CI LIF Splitter

## Introduction

What to do with large or huge Leica LAS-X LIF files? Opening them can be a pain. With CI LIFSplitter, you can now split (i.e., extract) images to separate LIF files or optionally .QTIFF (RGB only) files.

## Features

- **Splitting LIF/XLEF Files**: Easily split large LIF or XLEF files into multiple smaller LIF files.
- **Convert to .QTIFF**: Optionally convert 2D RGB images to .QTIFF Slide format. These files are saved with JPG compression and contain pyramids and a thumbnail. They are compatible with QuPath, AperioImageScope, Omero, Fiji (ImageJ), and even many more imaging programs when renamed to .tif.

## Usage

1. **Add Files**: First, add one or more LIF/XLEF files to the tree.
2. **Select Nodes**: Select one or more nodes to extract.
3. **Split Files**: Click 'Split into separate LIF Files' to start the extraction process.
4. **Convert RGB Images**: Optionally, check the 'Convert RGB Images to .QTIFF' box to convert 2D RGB images to .QTIFF format.

### Canceling and Error Handling

- You can cancel the splitting process. It will stop once the current splitting is done.
- If an error occurs, the GUI can be reset by clicking the 'R' button.

## Screenshot

![CI LIF Splitter Interface](https://github.com/Cellular-Imaging-Amsterdam-UMC/CI_LIF-Splitter/blob/main/Schermafbeelding_2024-05-29_152728.png?raw=true)(./)

## Version

- **Version**: 1.1

## Author

- **Author**: [Ron Hoebe](mailto:r.a.hoebe@amsterdamumc.nl)

## License

- **License**: MIT

## Source

- **Source**: [https://software.cellularimaging.nl](https://software.cellularimaging.nl)

## Installation

To install and run the CI LIFSplitter:

1. Download the latest release from the [source link](https://software.cellularimaging.nl).
2. Follow the installation instructions provided in the download package.

## Contributions

Contributions are welcome. Please follow the guidelines outlined in the CONTRIBUTING.md file in the repository.

---

This readme provides a comprehensive overview of the CI LIF Splitter, its features, and how to use it. For more details, visit the [official website](https://software.cellularimaging.nl).
