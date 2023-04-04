using Base.Threads
Threads.nthreads()

using CSV, DataFrames, Dates

"""
    data_processing(country::String)

Process the confirmed cases, recovered and death data for a given country.

    filter_data_by_date(data::DataFrame, start_date::Date, num_days::Int)

Filter the data by date.

# Arguments
- `country::String`: The name of the country to process the data for.
- `data::DataFrame`: The DataFrame to be filtered.
- `start_date::Date`: The start date of the filtered data.
- `num_days::Int`: The number of days from the start date to be included in the filtered data.

# Returns
- `df::DataFrame`: A DataFrame containing the processed data.
- `filtered_data::DataFrame`: A DataFrame containing the filtered data.

# Examples
```julia-repl
julia> data = data_processing("US")
julia> filtered_data = filter_data_by_date(data, Date(2020, 3, 1), 30)
   │ Row │ dates      │ confirmed │ recovered │ death     │
   │     │ Date       │ Int64     │ Int64     │ Int64     │
───┼─────┼────────────┼───────────┼───────────┼───────────┤
 1 │  40 │ 2020-03-01 │        76 │         7 │        1  │
 2 │  41 │ 2020-03-02 │       101 │         7 │        6  │
 3 │  42 │ 2020-03-03 │       121 │         8 │        7  │
 4 │  43 │ 2020-03-04 │       201 │         8 │       12  │
 5 │  44 │ 2020-03-05 │       241 │         8 │       12  │
 6 │  45 │ 2020-03-06 │       328 │         8 │       17  │
 7 │  46 │ 2020-03-07 │       413 │         8 │       19  │
 8 │  47 │ 2020-03-08 │       555 │         8 │       22  │
 9 │  48 │ 2020-03-09 │       703 │         8 │       26  │
10 │  49 │ 2020-03-10 │       994 │        12 │       30  │
11 │  50 │ 2020-03-11 │      1301 │        12 │       38  │
12 │  51 │ 2020-03-12 │      1663 │        13 │       41  │
   ⋮   │     ⋮         │     ⋮       │     ⋮       │     ⋮       │
This function reads the confirmed cases, recovered and death data for all countries from CSV files, selects the row corresponding to the specified country, extracts the date strings and converts them to Date objects, and returns a DataFrame containing the confirmed cases, recovered and death and dates for the specified country.
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
    data_row_death = data_confirmed[row, :]
    country_data_confirmed = [i for i in values(data_row_confirmed[5:end])]
    country_data_recovered = [i for i in values(data_row_recovered[5:end])]
    country_data_death = [i for i in values(data_row_death[5:end])]

    date_strings = String.(names(data_confirmed))[5:end]
    format = Dates.DateFormat("m/d/Y")
    dates = parse.(Date, date_strings, format) + Year(2000)

    df = DataFrame(dates=dates, confirmed=country_data_confirmed, recovered=country_data_recovered, death=country_data_death)
    return df
end


function filter_data_by_date(data::DataFrame, start_date::Date, num_days::Int)
    end_date = start_date + Day(num_days)
    filtered_data = data[data.dates.>=start_date, :]
    filtered_data = filtered_data[filtered_data.dates.<=end_date, :]
    return filtered_data
end

