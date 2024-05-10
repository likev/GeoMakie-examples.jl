using CairoMakie
using Makie: colorschemes

fig = Figure(size=(1000,600))
ga = fig[1, 1:2]
gb = fig[2, 1] = GridLayout()

# a practical solution to ensure that each point is assigned one of the 5 discrete colors in a repeating pattern.
ax1,_ = scatter(ga[1,1], range(1, 7, 20), fill(0, 20), color=repeat(1:5, 4), colormap=:Spectral_5, markersize = 50)

text!(ax1, 4, 0, text = "scatter-Spectral_5", align = (:center, :bottom), offset = (0, 30))


xs = -5:5
ys = -5:5
zs = [x^2 + y^2 for x in xs, y in ys]

ax2 = Axis(ga[1,2], aspect = AxisAspect(1), title = "AxisAspect(1) contour-Spectral_5")
cf2 = contour!(ax2, xs, ys, zs, levels=[i^2 for i in 1:5], color=colorschemes[:Spectral_5][1:5]) 

text!(ax2, 0, 5, text = "contour-Spectral_5", align = (:center, :bottom), offset = (0, 30))

limits!(ax2, -5, 5, -5, 7)

ax3 = Axis(gb[1,1], aspect = AxisAspect(1), title = "AxisAspect(1) contourf-Spectral_5")
cf3 = contourf!(ax3, xs, ys, zs, levels=[i^2 for i in 1:5], colormap=colorschemes[:Spectral_5][1:4])

text!(ax3, 0, 5, text = "contourf-Spectral_5", align = (:center, :bottom), offset = (0, 30))

limits!(ax3, -5, 5, -5, 7)

Colorbar(gb[1,2], cf3 ; label = "contourf-Spectral_5", ticks =[i^2 for i in 1:5], alignmode=Mixed())

colgap!(gb, 1, 10)

save("scatter20.png", current_figure())