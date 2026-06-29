# Bachelor Thesis: Detecting water stress via land surface temperatures

**Degree program:** Geography

**Author:** Jonathan Lanz

**Supervision:** Benjamin David Stocker, Yousra El-Mejjaouy

### Description

This is the project containing all data and code for my Bachelor thesis "Detecting water stress via land surface temperatures". 
Drought-induced plant water stress is difficult to monitor at meaningful spatial scales. While remote sensing offers insight into water availability in the uppermost part of the soil, it remains difficult to determine soil moisture in deeper soil horizons. Land surface temperature (LST), however, carries information about the entire rooting zone, since evapotranspiration — and thus evaporative cooling of the surface — is reduced when plants suffer from water stress. This characteristic is used in this study, conducted in Western Switzerland, where observed land surface temperatures are compared to modelled potential land surface temperatures, computed with a random forest model trained only on days where plant water availability is sufficient. The difference ΔLST between observed and potential land surface temperature then serves as a proxy for plant water stress.
The approach was tested in an exploratory manner. It could be shown that ΔLST is larger under dry conditions, quantified using the potential cumulative water deficit (PCWD). Almost the entire study area shows a measurable ΔLST on dry days, while on moist days this effect is largely absent. Time series of ΔLST compared with PCWD also show promising correlations. These results suggest that the methodology used in this study may serve as a new approach to quantify plant water stress in the deeper rooting zone. Next steps would be to improve the spatial resolution and to validate ΔLST against ground truth measurements.


### Data
I am working with MODIS & SRTM data that I downloaded via AppEEARS and ERA5-Land data provided by GECO Bern. Additionally, I use a topographic radiation index that was calculated by Ting Tan using the Copernicus DEM.

### Reproduction of the workflow
**Folder Structure:** The folder "data-raw" contains the raw data (empty because files are too large for GitHub), while the folder "data" contains pre-processed data. The "analysis" folder contains R scripts for further data processing and model training. The "R" folder contains R functions that are used in the analysis. Finally, the "vignettes" folder contains .Rmd files where the main analysis is conducted. All figures and plots that are generated during the project are stored in the "fig" folder. 

**Reproduction:** The intended reproduction is the reproduction of the analysis part and results of the project. It is not possible to reproduce the entire workflow (including data downloading and rangling of the raw data) from this repository since the original data is too large. If you wish reproduce the workflow in it's entirety, please contact me or GECO Bern. 
 
The R scripts in and "analysis" are numbered from 05 to 11. To reproduce the workflow, you must simply execute the scripts in this order. The final results can then be generated executing the .Rmd files in "vignettes".


### Literature:

Ahmad, U., Alvino, A., & Marino, S. (2021). A Review of Crop Water Stress Assessment Using Remote Sensing. Remote Sensing, 13(20). https://doi.org/10.3390/rs13204155

Gerhards, M., Schlerf, M., Mallick, K., & Udelhoven, T. (2019). Challenges and Future Perspectives of Multi-/Hyperspectral Thermal Infrared Remote Sensing for Crop Water-Stress Detection: A Review. Remote Sensing, 11(10). https://doi.org/10.3390/rs11101240

Le, T. S., Harper, R., & Dell, B. (2023). Application of Remote Sensing in Detecting and Monitoring Water Stress in Forests. Remote Sensing, 15(13). https://doi.org/10.3390/rs15133360

Li, Z.-L., Wu, H., Duan, S.-B., Zhao, W., Ren, H., Liu, X., & Leng, P. (2023). Satellite Remote Sensing of Global Land Surface Temperature: Definition, Methods, Products, and Applications. Reviews of Geophysics, 61. https:// doi.org/10.1029/2022RG000777

Stocker, B. D., Zscheischler, J., Keenan, T. F., Prentice, I. C., Peñuelas, J., & Seneviratne, S. I. (2018). Quantifying soil moisture impacts on light use efficiency across biomes. New Phytologist, 218, 1430–1449. https://doi.org/10.1111/nph.15123

