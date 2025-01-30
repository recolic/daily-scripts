import torch
import numpy as np

def product_to_vec(productObj):
    # col size: - 6889 7343 - 86614 -
    # offset: - +87000 +94000 - 0 -
    # sum space: 102000 -> 500
    ids, price, icls = productObj
    

def algo_PCA(nparr, n_newD):
    """ 
    Designed to compress data.
    from mxn(m as sampleVctLength, n as sampleDim) to mxn_newD
    """
    meanVal = np.mean(nparr, axis = 0)  # get average by col
    meantDat = nparr - meanVal

    covMat = np.cov(meantDat, rowvar = 0)  # Get coVari
    eigVals, eigVects = np.linalg.eig(np.mat(covMat)) # Get eigenVal + Vect

    eigValIndice=np.argsort(eigVals)  # Small to Large
    n_eigValIndice=eigValIndice[-1:-(n_newD+1):-1]
    n_eigVect=eigVects[:,n_eigValIndice]
    reconMat = np.dot(meantDat, n_eigVect)  # Re-construct data

    return reconMat, lambda mToConv: (mToConv - meanVal).dot(n_eigVect)
