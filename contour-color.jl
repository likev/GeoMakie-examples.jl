using CairoMakie

# a practical solution to ensure that each point is assigned one of the 5 discrete colors in a repeating pattern.
f, ax, sc = scatter(range(1, 7, 20), fill(0, 20), color=repeat(1:5, 4), colormap=:Spectral_5, markersize = 50)

text!(ax, 4, 0, text = ":Spectral_5", align = (:center, :bottom), offset = (0, 30))

save("scatter20.png", current_figure())