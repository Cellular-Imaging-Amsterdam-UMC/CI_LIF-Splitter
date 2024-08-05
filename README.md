# CI LIF Splitter

## Version 1.2

### Overview

*CI LIF Splitter* is a program designed to split images from multiple LIF, XLEF, or LOF files into separate LIF files or to convert 2D or 3D (maximum intensity projection) images to QPTIFF format (Akoya Biosciences®).

### Selecting Images

1. Add (multiple) LIF, XLEF, or LOF files to the tree.
2. Select (multiple) nodes to extract.
3. Optionally, select the preview option from "None" (default) to "Ultra High Quality (slowest)".
   - A small preview is shown with sliders for Tiles, Time, and 3D Z-slice sequences.
   - For 3D sequences, there is a max projection toggle button.
   - You can zoom in and out with your mouse wheel when hovering over the preview.

### Operation for Splitting

1. Click "Split Selection..." to separate single images into separate LIF files.
2. You can cancel the splitting process, and it will stop when the current splitting is done.

### Operation for Converting to QPTIFF

1. Optionally convert 2D RGB or 3D (maximum intensity projection) images to QPTIFF format.
   - QPTIFF files contain both pyramids (downscaled versions of the original data) and a thumbnail.
   - QPTIFF files with LZW compression contain the original data without loss or scaling.
   - There is an option to scale 12-bit RGB images (from Leica MICA) to 8 bits for compatibility with QuPath.
   - QPTIFF files with RGB compression are 8 bits. There is an option to do Global MinMax scaling for RGB images or per channel MinMax for multichannel images. The JPG quality can also be adjusted.
   - QPTIFF files can be read by open-source programs such as QuPath, AperioImageScope, Omero, Fiji (ImageJ), and more, as well as commercial programs like HALO AI, PathAI, and others.
2. Click "Split Selection..." to separate single images into separate QPTIFF files.
   - Be aware, non-supported files (Tiles and Time Series) will be split to LIF.
   - 3D images are converted to maximum projection 2D images.
3. If an error occurs, the GUI can be reset by clicking the R button.

## Screenshot

![CI LIF Splitter Interface](https://github.com/Cellular-Imaging-Amsterdam-UMC/CI_LIF-Splitter/blob/main/Screenshot05-08-2024.png)

## Version

- **Version**: 1.2

## Author

- **Author**: [Ron Hoebe](mailto:r.a.hoebe@amsterdamumc.nl)

## License

- **License**: MIT

## Source

- **Source**: [https://software.cellularimaging.nl](https://software.cellularimaging.nl)

## Installation

To install and run the CI LIFSplitter (Microsoft Windows Systems only):

1. Download the latest release from the releases.
2. Follow the installation instructions provided in the download package.

## Prerequisites for running the code in MATLAB
1. Microsoft Windows Systems only
2. MATLAB: Ensure that you have MATLAB 2023b+ installed on your system.
3. Widgets Toolbox for MATLAB App Designer Components: This toolbox is required to run CI LIFSplitter. 
Download and install the Widgets Toolbox from [MathWorks File Exchange](https://nl.mathworks.com/matlabcentral/fileexchange/83328-widgets-toolbox-matlab-app-designer-components).

## Contributions

Contributions, Question and Test Files are welcome.

---

This readme provides a comprehensive overview of the CI LIF Splitter, its features, and how to use it. For more details, visit the [official website](https://software.cellularimaging.nl).
