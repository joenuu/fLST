# Bachelor Thesis: Detecting water stress via land surface temperatures

**Degree program:** Geography

**Author:** Jonathan Lanz

**Supervision:** Benjamin David Stocker, Yousra El-Mejjaouy

### Description

This is the project containing all data and code for my Bachelor thesis "Detecting water stress via land surface temperatures". 
Land surface temperatures (LST) reflect climatic conditions at the land surface (air temperature, radiation), and surface properties. The clue is that they also reflect to what extent water vapour fluxes cool surfaces and that plants have a strong influence on them. Hence, the activity of plants and the degree to which they are water limited have an imprit on remotely sensed LST. The challenge is to disentangle this signal from (big) satellite data. If a solution is found, it will yield a novel approach for interpreting high resolution LST data for informing our understanding of vegetation water stress across space.
Since a bachelor thesis is limited in time and scale, I will develop a model that estimates LST from meteorological and vegetational variables that can also be sensed from space. This should enable me to estimate the LST for moist surfaces. By comparing this with actual LST measurements, conclusions about water stress in the surface could be made. 
The approach I will take aims to fill a research gap in this topic. By testing this on a relatively small scale, I will be able to make a statement about 1) the influence of LST on water stress and 2) if a model of this kind could work for broader research.

### Data
I am working with MODIS & SRTM data that I downloaded via AppEEARS and ERA5-Land data provided by GECO Bern. Additionally, I use a topographic radiation index that was calculated using the Copernicus DEM.

### Reproduction of the workflow
It is not possible to reproduce the entire workflow, including data downloading, since the original data is too large. The scripts in the folder "data-raw" give insight into the extracting process of the data. If you wish reproduce the workflow in it's entirety, please contact me or GECO Bern. 

For the reproduction of the main analysis, it is sufficient to work with data from the folder "data" which contains the pre-processed data. The "analysis" folder contains R scripts for further data processing and model training. The "R" folder contains R functions that are used in the analysis. Finally, the "vignettes" folder contains .Rmd files where the main analysis is conducted. All figures and plots that are generated during the project are stored inn the "figures" folder.

Every .R and .Rmd file has a number. Follow the numbers in rising order to execute a clean reproduction of the workflow.

### Literature:

Ahmad, U., Alvino, A., & Marino, S. (2021). A Review of Crop Water Stress Assessment Using Remote Sensing. Remote Sensing, 13(20). https://doi.org/10.3390/rs13204155

Gerhards, M., Schlerf, M., Mallick, K., & Udelhoven, T. (2019). Challenges and Future Perspectives of Multi-/Hyperspectral Thermal Infrared Remote Sensing for Crop Water-Stress Detection: A Review. Remote Sensing, 11(10). https://doi.org/10.3390/rs11101240

Le, T. S., Harper, R., & Dell, B. (2023). Application of Remote Sensing in Detecting and Monitoring Water Stress in Forests. Remote Sensing, 15(13). https://doi.org/10.3390/rs15133360

Li, Z.-L., Wu, H., Duan, S.-B., Zhao, W., Ren, H., Liu, X., & Leng, P. (2023). Satellite Remote Sensing of Global Land Surface Temperature: Definition, Methods, Products, and Applications. Reviews of Geophysics, 61. https:// doi.org/10.1029/2022RG000777

Stocker, B. D., Zscheischler, J., Keenan, T. F., Prentice, I. C., Peñuelas, J., & Seneviratne, S. I. (2018). Quantifying soil moisture impacts on light use efficiency across biomes. New Phytologist, 218, 1430–1449. https://doi.org/10.1111/nph.15123

