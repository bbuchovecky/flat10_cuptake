import numpy as np
import xarray as xr
import time
import os

var = "TOTSOMC"

# Define landunit types
typlunit_name = np.array([
    'vegetated_or_bare_soil',
    'crop',
    "UNUSED",
    "landice_multiple_elevation_classes",
    "deep_lake",
    "wetland",
    "urban_tbd",
    "urban_hd",
    "urban_md",
])
typlunit = np.arange(9)

# Define component names
components = {
    "lnd": "clm2",
    "atm": "cam",
}

# Load dataset
indir = "~/scratch/archive/"
outdir = "/glade/work/bbuchovecky/FLAT10_analysis"

casename = "b.e21.B1850.f09_g17.FLAT10ctrl-esm.001.leafcn_high.bgc_spinup"
domain = "lnd"
hist_type = "h4"

dataset = xr.open_mfdataset(
    f"{indir}/{casename}/{domain}/hist/{casename}.{components[domain]}.{hist_type}.*.nc")
print("finished loading dataset")

# Define variables
landunit = dataset["landunit"]
lat = dataset["lat"]
lon = dataset["lon"]
land1d_ixy = dataset["land1d_ixy"].astype(int)
land1d_jxy = dataset["land1d_jxy"].astype(int)
land1d_ityplunit = dataset["land1d_ityplunit"].astype(int)
ts = dataset["time"]
nts = dataset["time"].size

# Create empty list to store gridded data
gridded_data = []

# Start timing
start = time.time()

# Iterate through the time steps
print("starting iteration through time steps")
for t in range(nts):

    # Create empty DataArray to store gridded data for each time step
    gridded = xr.DataArray(
        data=np.full((lat.size, lon.size, typlunit.size), fill_value=np.nan),
        dims=["lat", "lon", "typlunit"],
        coords={
            "lat": lat,
            "lon": lon,
            "typlunit": np.arange(9),
            "typlunit_name": (("typlunit"), typlunit_name)},
        name=var,
        attrs=dataset[var].attrs,
    )

    for lunit in range(landunit.size):
        if lunit % 1000 == 0:
            print(f"t={t}, lunit={lunit}, runtime={time.time() - start : 0.2f}")

        ityplunit = land1d_ityplunit.isel(time=t, landunit=lunit).values - 1

        # skips non-vegetated or bare soil landunits, cuts runtime in half
        if ityplunit != 0:
            continue

        jxy = land1d_jxy.isel(time=t, landunit=lunit).values - 1
        ixy = land1d_ixy.isel(time=t, landunit=lunit).values - 1

        gridded[jxy, ixy, ityplunit] = dataset[var].isel(
            time=t, landunit=lunit).values

    gridded_data.append(gridded)

gridded_data = xr.concat(gridded_data, dim="time").assign_coords(
    {"time": dataset["time"]})

print(f"time to grid {var}: {time.time() - start}")

# Save gridded data
if os.path.exists(f"{outdir}/{casename}/{domain}/hist") is False:
    os.makedirs(f"{outdir}/{casename}/{domain}/hist")

time_range = str(ts[0].values)[:7].replace("-", "") + \
    "-" + str(ts[-1].values)[:7].replace("-", "")

gridded_data.to_netcdf(
    f"{outdir}/{casename}/{domain}/hist/{casename}.{components[domain]}.{hist_type}.{time_range}.{var.upper()}.vegonly.nc")
