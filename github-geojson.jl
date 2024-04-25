using Makie, CairoMakie, GeoMakie
import Downloads
using GeoMakie.GeoJSON
# using GeometryBasics
using GeoMakie.GeoInterface


const LOAD_CACHE = Dict{String, Any}()

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


fieldlons = -180:180;
fieldlats = -90:90;
field = [exp(cosd(lon)) + 3(lat / 90) for lon in fieldlons, lat in fieldlats]

img = rotr90(GeoMakie.earth())
land = GeoMakie.land()

fig = Figure(size=(1500, 1000))

ga1 = GeoAxis(fig[1, 1]; dest="+proj=ortho +lon_0=110 +lat_0=35",limits=(70,150, 10, 60), title="Orthographic\n ");

ga2 = GeoAxis(fig[1, 2]; dest="+proj=moll", title="Image of Earth\n ")
ga3 = GeoAxis(fig[2, 1]; title="Plotting polygons")
ga4 = GeoAxis(fig[2, 2]; dest="+proj=natearth", title="Auto limits") # you can plot geodata on regular axes too

surface!(ga1, fieldlons, fieldlats, field; colormap=:rainbow_bgyrm_35_85_c69_n256, shading=NoShading)
lines!(ga1, GeoMakie.coastlines())
poly!(ga1, china_geojson("china"); strokewidth = 0.3, color=:gray90, rasterize = 5)
poly!(ga1, china_geojson("henan"); strokewidth = 0.5, color=:gray80, rasterize = 5)
poly!(ga1, china_geojson("luoyang"); strokewidth = 0.7, color=:gray70, rasterize = 5)

image!(ga2, -180 .. 180, -90 .. 90, img; interpolate=false) # this must be included
poly!(ga3, land[50:100]; color=1:51, colormap=(:plasma, 0.5))
poly!(ga4, land[22]);

save("example.png", fig)
