
# Import libraries
from mpl_toolkits import mplot3d
import numpy as np
import matplotlib.pyplot as plt
 
def read_input(fn):
    with open(fn) as f:
        return f.read().strip().split("\n")

def plot_file(fn, ax):
    input = read_input(fn)

    matrix = [line.split("\t") for line in input]
    X = np.arange(1, 11, 1)
    Y = np.arange(1, 11, 1)
    X, Y = np.meshgrid(X, Y)

    p1 = np.array([[float(line[index]) for index in range(0, len(line), 2)] for line in matrix])
    p2 = np.array([[float(line[index]) for index in range(1, len(line), 2)] for line in matrix])

    ax.plot_wireframe(X, Y, p1, color = "blue")
    ax.plot_wireframe(X, Y, p2, color = "green")


fig = plt.figure()
ax = plt.axes(projection ="3d")
plot_file("21.out", ax)
plt.show()


for angle in range(70,210,2):
    fig = plt.figure()
    ax = plt.axes(projection ="3d")
    plot_file("21.out", ax)

    ax.view_init(30,angle)

    filename='21_rot'+str(angle)+'.png'
    plt.savefig(filename, dpi=96)
    plt.gca()
