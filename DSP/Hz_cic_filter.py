import numpy as np
import matplotlib.pyplot as plt


D = 80
D2 = 4
N = 3
Fs = 2750000


w = np.linspace(-np.pi, np.pi, 2048)
z = np.exp(-1j*w)
x = w*Fs/(np.pi*2)

#Hcic1 = np.exp(-1j*w*(D-1)/2)*np.sin(w*D/2)/np.sin(w/2)


#Hcic = 1/D * np.abs((np.sin(np.pi*f*D)/np.sin(np.pi*f))**N)
Hcic2 = 1/D * ((1-z**(-D))/(1-z**(-1)))**N
#Hcic3 = 1/D2 * ((1-z**(-D2))/(1-z**(-1)))**N

#plt.plot(x[30000:33000], Hcic[30000:33000])
plt.yscale("log")
plt.plot(x, np.abs(Hcic2)/np.max(np.abs(Hcic2)))
#plt.plot(x, np.abs(Hcic3))
plt.grid()
plt.show()
