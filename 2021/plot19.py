
# Import libraries
from mpl_toolkits import mplot3d
import numpy as np
import matplotlib.pyplot as plt
 
def read_input(fn):
    with open(fn) as f:
        return f.read().strip().split("\n")

def plot_file(fn, ax, color):
    input = read_input(fn)
    x = []
    y = []
    z = []

    for line in input:
        xp,yp,zp = line.split(",")
        x.append(int(xp))
        y.append(int(yp))
        z.append(int(zp))

    ax.scatter3D(x, y, z, color = color)


for angle in range(70,210,2):
    fig = plt.figure()
    ax = plt.axes(projection ="3d")
    plot_file("19.out", ax, "green")
    plot_file("19b.out", ax, "red")

    ax.view_init(30,angle)

    filename='19_rot'+str(angle)+'.png'
    plt.savefig(filename, dpi=96)
    plt.gca()
