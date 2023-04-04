module CovidModelling
using CSV, DataFrames, Plots, Dates

export data_processing, filter_by_date, plot_covid_cases

"""
`data_processing(country::String) -> DataFrame`

Returns a DataFrame containing COVID-19 data for a given country.

# Arguments
- `country::String`: The name of the country to retrieve data for.

# Examples
```julia
data = data_processing("Nigeria")
```

# Returns
- A DataFrame containing the COVID-19 data for the given country.
"""
function data_processing(country::String)
    data_confirmed = CSV.read("data/exp_raw/confirmed_cases_global.csv", DataFrame)
    data_recovered = CSV.read("data/exp_raw/recovered_global.csv", DataFrame)
    data_death = CSV.read("data/exp_raw/death_global.csv", DataFrame)
    rename!(data_confirmed, 1 => "province", 2 => "country")
    rename!(data_recovered, 1 => "province", 2 => "country")
    rename!(data_death, 1 => "province", 2 => "country")
    countries = collect(data_confirmed[:, 2])
    row = findfirst(countries .== country)
    data_row_confirmed = data_confirmed[row, :]
    data_row_recovered = data_recovered[row, :]
    data_row_death = data_death[row, :]
    country_data_confirmed = [i for i in values(data_row_confirmed[5:end])]
    country_data_recovered = [i for i in values(data_row_recovered[5:end])]
    country_data_death = [i for i in values(data_row_death[5:end])]

    date_strings = String.(names(data_confirmed))[5:end]
    format = Dates.DateFormat("m/d/Y")
    dates = parse.(Date, date_strings, format) + Year(2000)

    df = DataFrame(dates=dates, confirmed=country_data_confirmed, recovered=country_data_recovered, death=country_data_death)
    return df
end


"""
`filter_by_date(data::DataFrame, start_date::Date, num_days::Int) -> DataFrame`

Filters a DataFrame of COVID-19 data to a given date range.

# Arguments
- `data::DataFrame`: The DataFrame to filter.
- `start_date::Date`: The start date of the date range.
- `num_days::Int`: The number of days from the start date to include in the range.

# Examples
```julia
filtered_data = filter_by_date(data, Date(2020, 3, 1), 30)
```

# Returns
- A DataFrame containing only the rows of `data` that fall within the given date range.
"""
function filter_by_date(data::DataFrame, start_date::Date, num_days::Int)
    end_date = start_date + Day(num_days)
    filtered_data = data[data.dates.>=start_date, :]
    filtered_data = filtered_data[filtered_data.dates.<=end_date, :]
    return filtered_data
end


"""
    plot_covid_cases(data::DataFrame, country_name::String)

Plots the daily confirmed COVID-19 cases for a specific country.

# Arguments
- `data::DataFrame`: the DataFrame containing the COVID-19 data
- `country_name::String`: the name of the country to plot the data for
"""
function plot_covid_cases(data::DataFrame, country_name::String)
    x = data.dates
    y = data.confirmed
    plot(x, y, legend=:topleft, labels=country_name, linewidth=3,
        title="COVID-19 Confirmed Cases", xlabel="Dates", ylabel="Daily Confirm Cases")
    savefig("plots/$(country_name).png")
    return nothing
end

end # module