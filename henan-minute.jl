import JSON

using Dates, Downloads, FileIO, CairoMakie, GeoMakie

import Downloads
using GeoMakie.GeoJSON
# using GeometryBasics
using GeoMakie.GeoInterface


const LOAD_CACHE = Dict{String,Any}()

function china_geojson(area_name::String)
    if area_name === "china"
        return get!(LOAD_CACHE, "china") do
            GeoJSON.read(read(Downloads.download("https://github.com/lizhiqianduan/geojson-of-china-full/raw/master/data/100000_geojson_full.json"), String))
        end
    elseif area_name === "henan"
        return get!(LOAD_CACHE, "henan") do
            GeoJSON.read(read(Downloads.download("https://github.com/lizhiqianduan/geojson-of-china-full/raw/master/data/410000_geojson_full.json"), String))
        end
    elseif area_name === "luoyang"
        return get!(LOAD_CACHE, "luoyang") do
            GeoJSON.read(read(Downloads.download("https://github.com/lizhiqianduan/geojson-of-china-full/raw/master/data/410300_geojson_full.json"), String))
        end
    end
end

include("../WindBarbs.jl/wind-barbs.jl")
using .WindBarbs

timezone = 8
date1 = DateTime("2024-04-29 08:00", dateformat"yyyy-mm-dd HH:MM")
date2 = DateTime("2024-04-29 09:00", dateformat"yyyy-mm-dd HH:MM")

const host = "https://eleven-describing-blend-viewed.trycloudflare.com"

function fiveminute(time)
    yyyymmddHHMM = Dates.format(time, dateformat"yyyy-mm-dd%20HH:MM:00")
    "$host/Weather/ZDZ?projectname=&calltype=5&iquery=ZDZ.GetDataByCollectionCodeAndWeatherKeys|1|String;fiveminute|String;henan_county|String;wind_exmax|DateTime;$yyyymmddHHMM"
end



fig = Figure(size=(1500, 1000))

ga1 = GeoAxis(fig[1, 1]; dest="+proj=ortho +lon_0=113 +lat_0=34", limits=(110, 120, 30, 40), title="Orthographic\n ");
poly!(ga1, china_geojson("henan"); strokewidth=0.5, color=:gray95, rasterize=5)


time = Observable(0)

# https://docs.makie.org/stable/explanations/nodes/
last_result = nothing

ob_result = @lift begin
    try
        io = Downloads.download(fiveminute(date1 + Minute($time)), IOBuffer())
        seekstart(io)
        j = JSON.parse(io)

        xs::Vector{Real} = []
        ys::Vector{Real} = []
        vals::Vector{Real} = []
        dirs::Vector{Real} = []
        for row in j["Rows"]
            name, lon, lat, dir, val = row[2], row[5], row[6], row[28], row[29]
            push!(xs, lon)
            push!(ys, lat)
            push!(vals, val)
            push!(dirs, dir)
        end

        global last_result = (; xs, ys, vals, dirs)
    catch e
        if isa(e, RequestError)
            println("Error with the request: ", e)
        else
            println("Other error: ", e) # or e.msg
        end
    end

    last_result
end

xs = @lift($ob_result.xs)
ys = @lift($ob_result.ys)
vals = @lift($ob_result.vals)
dirs = @lift($ob_result.dirs)

scatter_wind!(ga1; xs, ys, vals, dirs)

# save("example-henan.png", fig)

timestamps = 0:5:Minute(date2 - date1).value
framerate = 1

# https://docs.makie.org/stable/api/#record
record(fig, "wind-time-animation.mp4", timestamps; framerate) do t
    time[] = t
end