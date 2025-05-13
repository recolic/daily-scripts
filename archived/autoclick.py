

import pymouse, time
m = pymouse.PyMouse()

while True:
    m.click(m.position()[0], m.position()[1])
    time.sleep(5)

