from vtk.numpy_interface import dataset_adapter as dsa
from vtk.numpy_interface import algorithms as algs
import numpy as np
input0 = inputs[0]

############################################
#           CREATING DATA
############################################

coordVec = input0.Points.Arrays[0]

# Cylindrical Coordinate Points
x = coordVec[:, 0]
y = coordVec[:, 1]
z = coordVec[:, 2]

radius = algs.sqrt(x**2 + y**2)
theta = algs.arctan2(y, x)

# Cylindrical Direction Vectors
# radVec
radVec = coordVec.copy()
radVec[:, 2] = radVec[:, 2] * 0
radVec = algs.norm(radVec)

# zVec
zVec = np.repeat([[0, 0, 1]], radVec[:, 0].size, axis=0)
zVec = algs.make_vector(*zVec.T)

# thetaVec
thetaVec = algs.cross(zVec, radVec)
thetaVec = algs.make_vector(*thetaVec.T)
thetaVec = algs.norm(thetaVec)

###########################################
#            OUTPUTING DATA
###########################################

# Cylindrical Coordinate Points
output.PointData.append(radius, "r")
output.PointData.append(theta, "theta")
output.PointData.append(z, 'z')

# Cylindrical Direction Vectors
output.PointData.append(radVec, 'rVec')
output.PointData.append(zVec, 'zVec')
output.PointData.append(thetaVec, 'thetaVec')

# for key in input0.PointData.keys():
#     output.PointData.append(input0.PointData[key], key