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
date1 = DateTime("2024-05-14 20:00", dateformat"yyyy-mm-dd HH:MM")
date2 = DateTime("2024-05-15 10:00", dateformat"yyyy-mm-dd HH:MM")

const host = "https://preservation-conviction-costa-madonna.trycloudflare.com"

function fiveminute(time)
    yyyymmddHHMM = Dates.format(time, dateformat"yyyy-mm-dd%20HH:MM:00")
    "$host/Weather/ZDZ?projectname=&calltype=5&iquery=ZDZ.GetDataByCollectionCodeAndWeatherKeys|1|String;fiveminute|String;henan_county|String;wind_exmax|DateTime;$yyyymmddHHMM"
end


time = Observable(0)
ax_title = Observable("")

# https://docs.makie.org/stable/explanations/nodes/
last_result = nothing
names::Vector{String} = []

ob_result = @lift begin
    try
        cur_time = date1 + Minute($time)
        io = Downloads.download(fiveminute(cur_time), IOBuffer())
        seekstart(io)
        j = JSON.parse(io)

        xs::Vector{Real} = []
        ys::Vector{Real} = []
        vals::Vector{Real} = []
        dirs::Vector{Real} = []

        global names = []
        for row in j["Rows"]
            name, lon, lat, dir, val = row[2], row[5], row[6], row[28], row[29]

            push!(xs, lon)
            push!(ys, lat)
            push!(names, name)

            if isa(dir, Real) && isa(val, Real) # check nothing
                push!(vals, val)
                push!(dirs, dir)
            else # insert 0 or we will get LoadError: DimensionMismatch: arrays could not be broadcast to a common size; got a dimension with lengths 120 and 121
                println(row)
                push!(vals, 0)
                push!(dirs, 0)
            end
        end

        ax_title[] = Dates.format(cur_time, dateformat"yyyy-mm-dd HH:MM:00")
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

fig = Figure(size=(1200, 1000))

ga1 = GeoAxis(fig[1, 1]; dest="+proj=ortho +lon_0=113 +lat_0=34", limits=(110, 117, 31, 37), title=ax_title);
poly!(ga1, china_geojson("henan"); strokewidth=0.5, color=:gray95, rasterize=5)

text!(ga1, xs[], ys[], text=names, fontsize=10, color=:gray30, align = (:center, :top))

scatter_wind!(ga1; xs, ys, vals, dirs, size=0.5)

# save("example-henan.png", fig)

timestamps = 0:5:Minute(date2 - date1).value
framerate = 6

# https://docs.makie.org/stable/api/#record
record(fig, "wind-time-animation20240514.mp4", timestamps; framerate) do t
    time[] = t
end