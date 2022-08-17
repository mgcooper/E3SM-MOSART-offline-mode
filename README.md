# E3SM-MOSART-offline-mode
This repository contains a set of utilities to set up an offline hillslope-mode simulation with MOSART (Model for Scale Adaptive River Transport) (Li et al. 2013), which is the river routing component of E3SM (Energy Exascale Earth System Model) (Golaz et al. 2019). The utilities convert spatial representations of land surface areas as hillslopes and river links provided by the Hillsloper utility (courtesy Jon Schwenk, Los Alamos National Laboratory) into land surface tiles representing computational hillslopes and river links, which are the basic computational elements used in MOSART.

<img src="/assets/img/mosart_sag_basin.png" width="324">
<!-- ![Alt text](/assets/img/mosart_sag_basin.png?raw=true "MOSART Sag Basin") -->

# usage
The example/ directory contains a set of scripts that create the input files for MOSART using a hillslope-based land surface discretization. The hillslopes are provided by the Hillsloper utility. Functions that convert the Hillsloper output to the correct format required to run the example scripts are contained in functions/. A complete example workbook is forthcoming. Interested users may contact Matt Cooper (matt.cooper@pnnl.gov) for further information.

# references

Golaz, J.-C., Caldwell, P. M., Van Roekel, L. P., Petersen, M. R., Tang, Q., Wolfe, J. D., et al. (2019). The DOE E3SM Coupled Model Version 1: Overview and Evaluation at Standard Resolution. Journal of Advances in Modeling Earth Systems, 11(7), 2089–2129. https://doi.org/10.1029/2018MS001603

Li, H., Wigmosta, M. S., Wu, H., Huang, M., Ke, Y., Coleman, A. M., & Leung, L. R. (2013). A Physically Based Runoff Routing Model for Land Surface and Earth System Models. Journal of Hydrometeorology, 14(3), 808–828. https://doi.org/10.1175/JHM-D-12-015.1