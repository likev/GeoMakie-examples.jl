using Dates, Downloads, FileIO, CairoMakie

timezone = 8
date1 = DateTime("2024-05-14 20:00", dateformat"yyyy-mm-dd HH:MM") - Hour(timezone)
date2 = DateTime("2024-05-15 10:00", dateformat"yyyy-mm-dd HH:MM") - Hour(timezone)

to2(m) = m > 9 ? "$m" : "0$m"

# http://image.nmc.cn/product/2023/04/27/RDCP/SEVP_AOC_RDCP_SLDAS3_ECREF_ACCN_L88_PI_20230427025400000.PNG

const BaseURL = "https://nh-appendix-other-cyber.trycloudflare.com"; #"http://image.nmc.cn"
function getLargeStc(partName, time)

    # parts = [['part1', 'ANWC'], ['part2', 'ANCN'], ['part3', 'ANEC'], ['part4', 'ASWC'], ['华中', 'ACCN'], ['part6', 'AECN'], ['华南', 'ASCN']];

    yyyymmddHHMM = Dates.format(time, dateformat"yyyymmddHHMM")
    "$BaseURL/product/$(year(time))/$(to2(month(time) ))/$(to2(day(time)))/RDCP/SEVP_AOC_RDCP_SLDAS3_ECREF_$(partName)_L88_PI_$(yyyymmddHHMM)00000.PNG"
end

# println(getLargeStc("ASCN", date1))
# println(getLargeStc("ASCN", date2))

function encodeURIComponent0(original_string::String)
    # simple replace
    replace(original_string, ":" => "%3A", "/" => "%2F")
end


time = Observable(0)
ax_title = Observable("")

# https://docs.makie.org/stable/explanations/nodes/
lastimg = nothing
img = @lift begin
    try
        cur_time = date1 + Minute($time)
        src = getLargeStc("ANCN", cur_time)
        
        println("downloading " * src)
        io = Downloads.download(src, IOBuffer()) # "https://current.sinaapp.com/CORS/?csurl=" * encodeURIComponent0(src)
        f = load(io)
        # println(typeof(f)) # Matrix{ColorTypes.RGBA{FixedPointNumbers.N0f8}}

        ax_title[] = Dates.format(cur_time + Hour(timezone), dateformat"yyyy-mm-dd HH:MM:00")
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

ax1 = Axis(fig[1, 1],aspect=DataAspect(), title=ax_title)
image!(ax1, img)

#save("radar1.png", fig)

timestamps = 0:6:Minute(date2 - date1).value
framerate = 5

# https://docs.makie.org/stable/api/#record
record(fig, "radar-henan-20240514.mp4", timestamps; framerate) do t
    time[] = t
end