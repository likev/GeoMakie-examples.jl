using Dates, Downloads, FileIO, CairoMakie

timezone = 8
date1 = DateTime("2024-04-27 14:30", dateformat"yyyy-mm-dd HH:MM") - Hour(timezone)
date2 = DateTime("2024-04-27 15", dateformat"yyyy-mm-dd HH") - Hour(timezone)

to2(m) = m > 9 ? "$m" : "0$m"

# http://image.nmc.cn/product/2023/04/27/RDCP/SEVP_AOC_RDCP_SLDAS3_ECREF_ACCN_L88_PI_20230427025400000.PNG

const BaseURL = "http://image.nmc.cn/product";
function getLargeStc(partName, time)

    # parts = [['part1', 'ANWC'], ['part2', 'ANCN'], ['part3', 'ANEC'], ['part4', 'ASWC'], ['part5', 'ACCN'], ['part6', 'AECN'], ['part7', 'ASCN']];

    yyyymmddHHMM = Dates.format(time, dateformat"yyyymmddHHMM")
    "$BaseURL/$(year(time))/$(to2(month(time) ))/$(to2(day(time)))/RDCP/SEVP_AOC_RDCP_SLDAS3_ECREF_$(partName)_L88_PI_$(yyyymmddHHMM)00000.PNG"
end

println(getLargeStc("ASCN", date1))
println(getLargeStc("ASCN", date2))

function encodeURIComponent0(original_string::String)
    # simple replace
    replace(original_string, ":" => "%3A", "/" => "%2F")
end


time = Observable(0)

img = @lift(getLargeStc("ASCN", date1 + Minute($time))
            |> (src -> Downloads.download("https://current.sinaapp.com/CORS/?csurl=" * encodeURIComponent0(src), IOBuffer()))
            |> load
            |> rotr90)


fig = Figure(; backgroundcolor=RGBf(0.98, 0.98, 0.98), size=(1000, 1000))

ax1 = Axis(fig[1, 1],aspect=DataAspect(), title="Default")
image!(ax1, img)

#save("radar1.png", fig)

timestamps = 0:6:Minute(date2 - date1).value
framerate = 1

record(fig, "time_animation.mp4", timestamps; framerate) do t
    time[] = t
end
#=

time = Observable(0.0)

xs = range(0, 7, length=40)

ys_1 = @lift(sin.(xs .- $time))
ys_2 = @lift(cos.(xs .- $time) .+ 3)

fig = lines(xs, ys_1, color = :blue, linewidth = 4,
    axis = (title = @lift("t = $(round($time, digits = 1))"),))
scatter!(xs, ys_2, color = :red, markersize = 15)

framerate = 30
timestamps = range(0, 2, step=1/framerate)

record(fig, "time_animation.mp4", timestamps;
        framerate = framerate) do t
    time[] = t
end
=#