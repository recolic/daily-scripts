# Minecraft runway planner
# Runway center begin at [lx, y, lz], end at [rx, y, rz], and width is width. 
# Output all points that need to be built

lx, lz = 16068, -2213
rx, rz = 16164, -2322
y = 62
width = 16

#####################
import math

k = (rz-lz) / (rx-lx)

# Iterate x if |k| < 1, iterate z if |k| > 1
rwLen = math.sqrt((rz-lz)**2 + (rx-lx)**2)
wz = width * rwLen / math.fabs(rx-lx)
for x in range(min(int(lx), int(rx)) - 10, max(int(lx), int(rx)) + 10):
    z = lz + (x-lx)*k
    # print("./create-wp.fish", x, y, int(z))
    print("./create-wp.fish", x, y, int(z + wz/2))
    print("./create-wp.fish", x, y, int(z - wz/2))

print("# Note: runway length ", rwLen)

############################
# calculate guide point

midx = (lx+rx)/2
midz = (lz+rz)/2
sinc = math.tan(6 /180*math.pi) * rwLen / 2
guidey = y - sinc
print("# Note: Glide path guide point: ", (midx, guidey, midz))



