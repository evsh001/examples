import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
import numpy as np
from matplotlib.ticker import MaxNLocator, MultipleLocator
from scipy import signal, fft
import copy
from scipy import signal



N = 32
Fin = 3300  
Fs = 2750000
Ts = 1/Fs
Nf = 2048
DR  = 80  # decimation ratio


def sin_gen():
    ##### Yin - входная последовательность подаваемая на delta-sigma modulator
    t = np.linspace(0, 10000*Ts, 10000)  # 128 точек, один полупериод
    Yin = np.sin(Fin*2.0*np.pi*t)
    
    #########################################
    #######################################

    ##### modulator2 версия моя
    Integr = 0
    Ymod = []
    for i in range(0, len(Yin)):
        if Integr >= 1:
            Integr = Integr + Yin[i] - 1
            Ymod.append(1)
        else:
            Integr = Integr + Yin[i] + 1
            Ymod.append(0)
        
    Xm_mod = fft.fft(Ymod, Nf)   # спектр модулированного сигнала
    xf = fft.fftfreq(Nf, Ts) 

    #######################################
    #######################################

    ## another way generate pwm signal
    # t = np.linspace(0, 4*128*Ts, 4*128)
    # pwm = signal.square(2*np.pi*1300000*t, duty=Yin/255)
    # pwm = (pwm + 1)/2
    # Xm_pwm = fft.fft(pwm, Nf)

    #######################################

    ######### FILTER SECTION ##############
    ########## sin3 #######################
    z1 = 0
    z2 = 0
    z3 = 0
    z4 = 0
    z5 = 0
    z6 = 0
    Ysinc3 = []
    count = 0
    for i in range(len(Ymod)):
        z1 = (Ymod[i] + z1)%4194304
        z2 = (z1 + z2)%4194304
        z3 = (z2 + z3)%4194304
        count += 1
        if count == DR:
            diff1 = (z4 - z3)%4194304
            # if diff1 < 0:
            #     print('diff1 < 0', diff1)
            z4 = copy.deepcopy(z3)

            diff2 = (diff1 - z5)%4194304 
            # if diff2 < 0:
            #     print('diff2 < 0', diff2)
            z5 = copy.deepcopy(diff1)

            diff3 = (diff2 - z6)%4194304
            # if diff3 < 0:
            #     print('diff3 < 0', diff3)
            z6 = copy.deepcopy(diff2)

            Ysinc3.append(diff3)
            count = 0

    Ysinc3 = np.array(Ysinc3)
    Xm4 = fft.fft(Ysinc3, Nf)
    print(z1,z2,z3)
    print(diff1,diff2,diff3)
    ##########################################

    ################ moving avarage filter #############
    Yavr = []
    B = 64
    for i in range(0, len(Ymod), DR):
        Yavr.append(sum(Ymod[i:i+B]))
    
    Yavr = np.array(Yavr)
    #print(Yavr)
    #Yavr = Yavr - (np.max(Yavr) - np.min(Yavr))/2

    # Xm3 = fft.fft(Yavr, Nf)
    # Ts2 = Ts*20
    # xf2 = fft.fftfreq(Nf, Ts2)
    # xf2 = fft.fftshift(xf2)

    #######################################
    ########## Построение графиков ########
    fig = plt.figure(figsize=[10,7], constrained_layout=True)
    gs = GridSpec(nrows=4, ncols=1, figure=fig)

    # входная последовательность, синусоида
    ax1 = plt.subplot(gs[0,0])
    #ax1.set_in_layout(True)
    ax1.set_title('Input signal')
    ax1.plot(Yin, label='input signal')
   

    # последовательность на выходе модулятора Ymod1
    ax2 = plt.subplot(gs[1,0])
    ax2.set_title('PWM ver1 output signal')
    ax2.plot(Ymod)
    #ax2.plot(pwm)
    
    
    # последовательность на выходе модулятора Ymod2
    ax3 = plt.subplot(gs[2,0])
    ax3.set_title('PWM ver2 (my) output signal')
    ax3.plot(Yavr)
    

    # Спектр модулированного сигнала
    ax4 = plt.subplot(gs[3,0])
    ax4.set_title('FFT')
    ax4.plot(Ysinc3)
    #ax4.plot(xf[:Nf//32], (np.abs(Xm_mod1[:Nf//32]))/256, label='fft pwm ver1')
    #ax4.plot(xf[:Nf//32], (np.abs(Xm_pwm[:Nf//32]))/256, label='fft pwm ver1')

    # ax5 = plt.subplot(gs[3,0])
    # ax5.plot(xf[:Nf//32], (np.abs(Xm_mod[:Nf//32]))/256, label='fft pwm ver2 (my)')

    



    ax1.grid()
    ax1.legend()
    ax2.grid()
    ax3.grid()
    ax4.grid()
    ax4.legend()
    # ax5.grid()
    # ax5.legend()
    plt.show()


if __name__ == "__main__":
    print("Table PDM sin")
    sin_gen()
