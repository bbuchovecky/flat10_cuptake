import numpy as np
import xarray as xr
import matplotlib.pyplot as plt


def get_flat10_variable(variable, domain, case, time_range=['0001-01', '0003-12'], experiment='ctrl-esm', use_mfdataset=False, verbose=False, reindex_like=None):
    '''
    Loads a single variable for a given time range from a FLAT10 simulation.
    '''
    # Get the CESM2 component for the given domain
    comp_dict = {
        'atm': 'cam',
        'lnd': 'clm2',
    }
    comp = comp_dict[domain]

    # Get the archive directory for the given case
    case_archive_dict = {
        '':            '/glade/campaign/cgd/tss/lawrence/archive',
        'leafcn_high': '/glade/derecho/scratch/bbuchovecky/archive',
        'leafcn_high.bgc_spinup.check_startup': '/glade/derecho/scratch/bbuchovecky/archive',
        'leafcn_low':  '/glade/derecho/scratch/bbuchovecky/archive',
    }
    archive_dir = case_archive_dict[case]

    # Add a <.> delimiter for the file name
    if case != '':
        case = '.'+case

    # Construct the case name
    case_name = f'b.e21.B1850.f09_g17.FLAT10{experiment}.001{case}'

    time_start = time_range[0]
    time_end = time_range[1]

    # FLAT10ctrl-esm simulation with standard parameter set only goes until 0030-12
    if (case == '') and (int(time_end[:4]) > 30):
        time_end = '0030-12'

    if use_mfdataset:
        try:
            # Construct the file path with a wildcard for the time period
            glob_file_name = f'{archive_dir}/{case_name}/{domain}/hist/{case_name}.{comp}.h0.*.nc'

            concat_da = xr.open_mfdataset(glob_file_name)
            concat_da = concat_da[variable].sel(time=slice(time_start, time_end))
    
        except OverflowError:
            print('OverflowError: manually loading and concatenating each monthly output file')
            use_mfdataset = False
    
    if not use_mfdataset:
        da_list = []
        
        start_year = int(time_start[:4])
        start_month = int(time_start[5:])

        end_year = int(time_end[:4])
        end_month = int(time_end[5:])

        total_length_in_months = (end_year - start_year)*12 + end_month
        if verbose: print(f'length of timeseries [month]: {str(total_length_in_months).zfill(4)}')

        for year in range(start_year, end_year):
            for month in range(1, 13):
                da = xr.open_dataset(f'{archive_dir}/{case_name}/{domain}/hist/{case_name}.{comp}.h0.{str(year).zfill(4)}-{str(month).zfill(2)}.nc')[variable]
                da_list.append(da.copy(deep=True))

        for month in range(1, end_month+1):
            da = xr.open_dataset(f'{archive_dir}/{case_name}/{domain}/hist/{case_name}.{comp}.h0.{str(end_year).zfill(4)}-{str(month).zfill(2)}.nc')[variable]
            da_list.append(da.copy(deep=True))    

        concat_da = xr.concat(da_list, 'time')
    
    if ('time' in concat_da.dims) and (concat_da.time.size > 1):
        concat_da = concat_da.sel(time=slice(time_start, time_end))
  
    if reindex_like is not None:
        concat_da = concat_da.reindex(lat=reindex_like.lat, lon=reindex_like.lon, method='nearest', tolerance=1e-4)

    return concat_da


def atm_area_average(da: xr.DataArray, area: xr.DataArray = None) -> xr.DataArray:
    """
    Calculate the area-weighted average of an atmospheric variable.

    Parameters:
    da (xr.DataArray): The data array containing the atmospheric variable to be averaged.
    area (xr.DataArray, optional): The data array containing the area weights. If not provided, 
                                   the function will retrieve the 'AREA' variable using the 
                                   get_flat10_variable function.

    Returns:
    xr.DataArray: The area-weighted average of the input data array.
    """
    if area is None:
        area = get_flat10_variable('AREA', 'atm', '', time_range=['0001-01', '0001-01']).isel(time=0)
    weights = area/area.sum(dim=['lat', 'lon'])
    return (da*weights).sum(dim=['lat','lon'])/weights.sum(dim=['lat','lon'])


def lnd_area_average(da: xr.DataArray, area: xr.DataArray = None, landfrac: xr.DataArray = None) -> xr.DataArray:
    """
    Calculate the area-weighted average of a land variable.

    Parameters:
    da : xr.DataArray)
        The data array containing the land variable to be averaged.
    area : xr.DataArray, optional
        The data array containing the area weights. If not provided, 
        the function will retrieve the 'area' variable using the 
        get_flat10_variable function.
    landfrac : xr.DataArray, optional   
        The data array containing the land fraction. If not provided, 
        the function will retrieve the 'landfrac' variable using the 
        get_flat10_variable function.

    Returns:
        xr.DataArray: The area-weighted average of the input data array.
    """
    if area is None:
        area = get_flat10_variable('area', 'lnd', '', time_range=['0001-01', '0001-01']).isel(time=0)
    if landfrac is None:
        landfrac = get_flat10_variable('landfrac', 'lnd', '', time_range=['0001-01', '0001-01']).isel(time=0)
    landweights = (landarea*landfrac)/(landarea*landfrac).sum(dim=['lat', 'lon'])
    return (da*landweights).sum(dim=['lat','lon'])/landweights.sum(dim=['lat','lon'])


def lnd_area_integrate(da: xr.DataArray, area: xr.DataArray = None, landfrac: xr.DataArray = None) -> xr.DataArray:
    """
    Calculate the area-integrated value of a land variable.

    Parameters:
    da (xr.DataArray): The data array containing the land variable to be integrated.
    area (xr.DataArray, optional): The data array containing the area weights. If not provided, 
                                    the function will retrieve the 'area' variable using the 
                                    get_flat10_variable function.
    landfrac (xr.DataArray, optional): The data array containing the land fraction. If not provided, 
                                        the function will retrieve the 'landfrac' variable using the 
                                        get_flat10_variable function.

    Returns:
    xr.DataArray: The area-integrated value of the input data array.
    """
    if area is None:
        area = get_flat10_variable('area', 'lnd', '', time_range=['0001-01', '0001-01']).isel(time=0)
    if landfrac is None:
        landfrac = get_flat10_variable('landfrac', 'lnd', '', time_range=['0001-01', '0001-01']).isel(time=0)
    return (da*area*landfrac*1e6).sum(dim=['lat','lon'])


def plot_lnd_area_average_timeseries(variable, domain, time_range=['0001-01', '0003-12'], experiment='ctrl-esm', use_mfdataset=False, time_average='month'):
    hgh = get_flat10_variable(variable, domain, 'leafcn_high', time_range, experiment, use_mfdataset, reindex_like=None)

    if time_average == 'year':
        hgh = tsp.calculate_annual_timeseries(hgh)

    hgh_lnd_area_avg = lnd_area_average(hgh)

    hgh_lnd_area_avg.plot(label='hgh')
    plt.legend()
    plt.title(f'area-averaged {variable} over land')


def plot_lnd_area_integrated_timeseries(variable, domain, time_range=['0001-01', '0003-12'], experiment='ctrl-esm', use_mfdataset=False, time_average='month'):
    hgh = get_flat10_variable(variable, domain, 'leafcn_high', time_range, experiment, use_mfdataset, reindex_like=None)

    if time_average == 'year':
        hgh = tsp.calculate_annual_timeseries(hgh)

    hgh_lnd_area_int = lnd_area_integrate(hgh)

    hgh_lnd_area_int.plot(label='hgh')
    plt.legend()
    plt.title(f'area-integrated {variable} over land')


def plot_atm_area_average_timeseries(variable, domain, time_range=['0001-01', '0003-12'], experiment='ctrl-esm', use_mfdataset=False, time_average='month'):
    hgh = get_flat10_variable(variable, domain, 'leafcn_high', time_range, experiment, use_mfdataset, reindex_like=None)

    if time_average == 'year':
        hgh = tsp.calculate_annual_timeseries(hgh)
    
    hgh_atm_area_avg = atm_area_average(hgh)

    hgh_atm_area_avg.plot(label='hgh')
    plt.legend()
    plt.title(f'area-averaged {variable}')