using Dates, Downloads, FileIO, CairoMakie

timezone = 8
date1 = DateTime("2024-04-27 13:00", dateformat"yyyy-mm-dd HH:MM") - Hour(timezone)
date2 = DateTime("2024-04-27 17:00", dateformat"yyyy-mm-dd HH:MM") - Hour(timezone)

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

# https://docs.makie.org/stable/explanations/nodes/
lastimg = nothing
img = @lift begin
    try
        src = getLargeStc("ASCN", date1 + Minute($time)) 
        io = Downloads.download("https://current.sinaapp.com/CORS/?csurl=" * encodeURIComponent0(src), IOBuffer())
        f = load(io)
        # println(typeof(f)) # Matrix{ColorTypes.RGBA{FixedPointNumbers.N0f8}}
        global lastimg = rotr90(f)
    catch e
        if isa(e, RequestError)
            println("Error with the request: ", e)
        else
            println("Other error: ", e) # or e.msg
        end  
    end
    lastimg
end

fig = Figure(; backgroundcolor=RGBf(0.98, 0.98, 0.98), size=(1000, 1000))

ax1 = Axis(fig[1, 1],aspect=DataAspect(), title="Default")
image!(ax1, img)

#save("radar1.png", fig)

timestamps = 0:6:Minute(date2 - date1).value
framerate = 1

# https://docs.makie.org/stable/api/#record
record(fig, "time_animation.mp4", timestamps; framerate) do t
    time[] = t
end