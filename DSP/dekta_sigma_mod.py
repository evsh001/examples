import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
import numpy as np
from matplotlib.ticker import MaxNLocator, MultipleLocator
from scipy import signal, fft
import copy


N = 32
Fs = 80000
Vref = 0

def delta_sigma():
    Ts = 1/Fs
    R = 20

    ##### Yin - входная последовательность подаваемая на delta-sigma modulator
    t = np.linspace(0, 3000*Ts, 3000)
    Yin = np.sin(95.0 * 2.0*np.pi*t) + np.sin(125.0 * 2.0*np.pi*t) + np.sin(150.0 * 2.0*np.pi*t) + np.sin(235.0 * 2.0*np.pi*t) + np.sin(300.0 * 2.0*np.pi*t) + np.sin(500.0 * 2.0*np.pi*t)
    Yin = Yin/np.max(Yin)
    ##### Спектр входной последовательности
    Nf = 2048
    Xm = fft.fft(Yin, Nf)
    xf = fft.fftfreq(Nf, Ts)
    xf = fft.fftshift(xf)                                                                              


    ##### modulator
    Integr = Yin[0]
    Ymod = []
    for i in range(1, len(Yin)):
        if Integr >= 0:
            temp = Yin[i] - 1
            Ymod.append(1)
        else:
            temp = Yin[i] + 1
            Ymod.append(-1)
        Integr = temp + Integr
        
    ##### Спектр выходной последовательности модулятора
    Xm2 = fft.fft(Ymod, Nf)

    ################ moving avarage filter #############
    Yavr = []
    B = 40
    for i in range(0, len(Ymod), R):
        Yavr.append(sum(Ymod[i:i+B+24]))
    
    Yavr = np.array(Yavr)
    print(Yavr)
    #Yavr = Yavr - (np.max(Yavr) - np.min(Yavr))/2

    Xm3 = fft.fft(Yavr, Nf)
    Ts2 = Ts*20
    xf2 = fft.fftfreq(Nf, Ts2)
    xf2 = fft.fftshift(xf2)

    ######################## CIC 3-order #########################
    M = 3
    z1 = 0
    z2 = 0
    z3 = 0
    z4 = 0
    z5 = 0
    z6 = 0
    Ycic = []
    count = 0
    for i in range(len(Ymod)):
        z1 = Ymod[i] + z1
        z2 = z1 + z2
        z3 = z2 + z3
        count += 1
        if count == R:
            x1 = z3 - z4
            z4 = copy.deepcopy(z3)
            x2 = x1 - z5 
            z5 = copy.deepcopy(x1)
            x3 = x2 - z6
            z6 = copy.deepcopy(x2)
            Ycic.append(x3)
            count = 0

    Ycic = np.array(Ycic)
    Xm4 = fft.fft(Ycic, Nf)

    ##########################################
    print('max Ycic', np.max(Ycic))
    print('max Yavr', np.max(Yavr))
    ##########################################

    ############### Compensation filter ###########################
    Ycomp = []
    Yp1 = np.pad(Ycic, (0, M*2), 'constant',  constant_values=(0, 0)) 
    Yp2 = np.pad(Ycic, (M, 0), 'constant',  constant_values=(0, 0))   # задержанная на M последовательность Ycic
    Yp3 = np.pad(Ycic, (2*M, 0), 'constant',  constant_values=(0, 0)) # задержанная на 2*M последовательность Ycic
    A = -10
    for i in range(len(Ycic)):
        Ycomp.append(Yp1[i] + A*Yp2[i] + Yp3[i])
    Ycomp = np.array(Ycomp)
    Xm5 = fft.fft(Ycomp, Nf)

    #######################################

    ########################## Impulse response Compensation filter ###########################

    Imp_resp = np.ones(1)
    Imp_resp = np.pad(Imp_resp, (0, 127), 'constant',  constant_values=(0, 0)) 
    Yp1 = np.pad(Imp_resp, (M, 0), 'constant',  constant_values=(0, 0))   # задержанная на M последовательность Imp_resp
    Yp2 = np.pad(Imp_resp, (2*M, 0), 'constant',  constant_values=(0, 0)) # задержанная на 2*M последовательность Imp_resp

    A = -10
    Yresp = []
    for i in range(len(Imp_resp)):
        Yresp.append(Imp_resp[i] + A*Yp1[i] + Yp2[i])
    Yresp = np.array(Yresp)
    #print(Yresp)

    Xm6 = fft.fft(Yresp, Nf)
    ###########################################################################################

    ################### H(z) Compensation filter ###########################
    A = -10     #filter from https://www.dsprelated.com/showarticle/1337.php
    M = 3
    w = np.linspace(0, np.pi, 128)
    Hz_comp = 1 + A*np.exp(-1j*w*M) + np.exp(-1j*w*2*M) 
    Hz_comp = np.abs(Hz_comp)
    ########################################################################
    # Hz_cic = (np.sin(w*R/2)/np.sin(w/2))**M
    # F = np.arange(0, Fs/R/2)          ### https://wirelesspi.com/cascaded-integrator-comb-cic-filters-a-staircase-of-dsp/
    # F_new = F/(Fs/R) 
    # Hz_cic_invers = (np.sin(np.pi*F_new/R)/np.sin(np.pi*F_new))**M
    G = 16
    Hz_cic = (np.sin(w*R/2)/np.sin(w/2))**M
    w_inv = np.linspace(-np.pi/R, np.pi/R, G)
    Hz_cic_invers = (np.sin(w_inv/2)/np.sin(w_inv*R/2))**M
    Hz_cic_invers = np.concatenate((Hz_cic_invers[G//2-1:], Hz_cic_invers[:G//2-1]))

    Hz_cic_invers2 = np.concatenate((Hz_cic_invers, Hz_cic_invers))
    for _ in range(R-2):
        Hz_cic_invers2 = np.concatenate((Hz_cic_invers2, Hz_cic_invers))

    FIR_coef = fft.ifft(Hz_cic_invers2)
    FIR_coef = fft.fftshift(FIR_coef)
    FIR_coef = FIR_coef[len(FIR_coef)//2-20:len(FIR_coef)//2+20]
    #FIR_coef = FIR_coef
    Xm7 = fft.fft(FIR_coef, Nf)
    #
    Hz_comp_new = FIR_coef[0] + np.exp(-1j*w*20)*FIR_coef[20]

    # Hz_comp_new = FIR_coef[0] + np.exp(-1j*w)*FIR_coef[1] + np.exp(-1j*w*2)*FIR_coef[2] + np.exp(-1j*w*3)*FIR_coef[3] + np.exp(-1j*w*4)*FIR_coef[4] + np.exp(-1j*w*5)*FIR_coef[5] + np.exp(-1j*w*6)*FIR_coef[6]
    # #
    new_sig = np.convolve(FIR_coef, Ycic)
    Xm8 = fft.fft(new_sig, Nf)



    fig = plt.figure(figsize=[10,7])
    gs = GridSpec(nrows=5, ncols=1, figure=fig)
    ax1 = plt.subplot(gs[0,0])
    #ax1.plot(np.abs(Hss))
    ax1.plot(Yin)
    #ax1.plot(Ymod)
    #ax1.set_yscale("log")
    #ax1.plot(xf[Nf//2:1152], np.abs(Xm2[:Nf//16]))
    ##ax1.xaxis.set_major_locator(MultipleLocator(base=8))

    ax2 = plt.subplot(gs[1,0])
    #ax2.xaxis.set_major_locator(MultipleLocator(base=2))
    ax2.plot(Yavr/64)
    #ax2.plot(Ycic/8192)
    #ax2.plot(Ycomp/65535)




    ax3 = plt.subplot(gs[2,0])
    # ax3.yaxis.set_major_locator(MultipleLocator(base=0.1))
    # ax3.xaxis.set_major_locator(MultipleLocator(base=8))
    ax3.set_yscale("log")
    #ax3.plot(xf[Nf//2:1152], np.abs(Xm[:Nf//16]))
    #ax3.plot(xf[Nf//2:1152], np.abs(Xm2[:Nf//16]))
    ax3.plot(xf2[Nf//2:], np.abs(Xm3[:Nf//2]/1000))
    ax3.plot(xf2[Nf//2:], np.abs(Xm4[:Nf//2]/150000))
    #ax3.plot(xf2[Nf//2:], np.abs(Xm5[:Nf//2]/1500000))
    ax3.plot(xf2[Nf//2:], np.abs(Xm8[:Nf//2])/16)
  
    # ax3.plot(xf[Nf//2:], np.abs(Xm[:Nf//2]))
    #ax3.plot(Ycic)

    ax4 = plt.subplot(gs[3,0])
    #ax4.set_yscale("log")
    #ax4.plot(xf2[Nf//2:], np.abs(Xm6[:Nf//2]))
    ax4.plot(new_sig)

    ax5 = plt.subplot(gs[4,0])
    ax5.set_yscale("log")
    # ax5.plot(Hz_comp)
    #ax5.plot(Hz_cic/20)
    # ax5.plot(Hz_cic*Hz_comp)
    #ax5.plot(Hz_cic_invers2)
    
    #ax5.stem(FIR_coef)
    #ax5.plot(abs(Xm7)[:Nf//2])
    #ax5.plot(xf2[Nf//2:], np.abs(Xm7[:Nf//2]))
    ax5.plot(Hz_cic)
    ax5.plot(abs(Hz_comp_new))
    ax5.plot(Hz_cic*abs(Hz_comp_new))
    

    ax1.grid()
    ax2.grid()
    ax3.grid()
    ax4.grid()
    ax5.grid()
    plt.show()


if __name__ == "__main__":
    print("Test fourier")
    delta_sigma()
