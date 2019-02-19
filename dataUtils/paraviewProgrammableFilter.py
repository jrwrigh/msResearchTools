from vtk.numpy_interface import dataset_adapter as dsa
from vtk.numpy_interface import algorithms as algs
import numpy as np
input0 = inputs[0]

############################################
#        CREATING COORDINATE DATA
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

############################################
#      CREATING CARTESIAN VECTOR DATA
############################################
VelMeanVec = algs.make_vector(input0.PointData['Mean_X_Velocity'].Arrays[0],
                              input0.PointData['Mean_Y_Velocity'].Arrays[0],
                              input0.PointData['Mean_Z_Velocity'].Arrays[0])

VelRMSEVec = algs.make_vector(input0.PointData['RMSE_X_Velocity'].Arrays[0],
                              input0.PointData['RMSE_Y_Velocity'].Arrays[0],
                              input0.PointData['RMSE_Z_Velocity'].Arrays[0])

############################################
#      CREATING CYLINDRICAL VECTOR DATA
############################################
VelocityVec = input0.PointData['Velocity'].Arrays[0]

CylVec = [radVec, thetaVec, zVec]
VectorDict = {
    "VelCyl": VelocityVec,
    "VelCylMean": VelMeanVec,
    "VelCylRMSE": VelRMSEVec
}

VectorCylDict = {}
for key in VectorDict.keys():
    VectorCylDict[key] = algs.make_vector(
        algs.dot(VectorDict[key], radVec), algs.dot(VectorDict[key], thetaVec),
        algs.dot(VectorDict[key], zVec))

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

# Cartesian Vector Data
output.PointData.append(VelMeanVec, 'Velocity_Mean')
output.PointData.append(VelRMSEVec, 'Velocity_RMSE')

# Cylindrical Vector Data
output.PointData.append(VectorCylDict['VelCyl'], 'VelocityCyl')
output.PointData.append(VectorCylDict['VelCylMean'], 'VelocityCyl_Mean')
output.PointData.append(VectorCylDict['VelCylRMSE'], 'VelocityCyl_RMSE')

# for key in input0.PointData.keys():
#     output.PointData.append(input0.PointData[key], key