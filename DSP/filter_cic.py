import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
import numpy as np
from matplotlib.ticker import MaxNLocator, MultipleLocator
from scipy import signal, fft


N = 32
Fs = 3200




def test():
    Ts = 1/Fs
  
    # Передаточная функция CIC фильтра
    D = 8
    w = np.linspace(-np.pi, np.pi, 1024)
    Hcic = np.exp(-1j*w*(D-1)/2)*np.sin(w*D/2)/np.sin(w/2)
    Hcic_lg = 20*np.log10(np.abs(Hcic)/max(np.abs(Hcic)))

    ##### y - входная последовательность подаваемая на CIC фитльтр
    t = np.linspace(0, 300*Ts, 300)
    Yin = np.sin(150.0 * 2.0*np.pi*t) + np.sin(125.0 * 2.0*np.pi*t) + np.sin(95.0 * 2.0*np.pi*t) + np.sin(235.0 * 2.0*np.pi*t) + np.sin(300.0 * 2.0*np.pi*t) + np.sin(500.0 * 2.0*np.pi*t)
    ##### Спектр входной последовательности
    Nf = 1024
    Xm = fft.fft(Yin, Nf)
    xf = fft.fftfreq(Nf, Ts)
    xf = fft.fftshift(xf)

    ##### integrator
    Y_int = [Yin[0]]
    for i in range(1, len(Yin)):
        Y_int.append(Y_int[-1] + Yin[i])

    ##### comb filter
    Yp1 = np.pad(Y_int, (0, D), 'constant',  constant_values=(0, 0)) 
    Yp2 = np.pad(Y_int, (D, 0), 'constant',  constant_values=(0, 0)) # задержанная на D входная последовательность
    Yout = Yp1 - Yp2                                                 # выходная последовательность гребенчатого фитльтра
    
    Xm2 = fft.fft(Yout/D, Nf) # спектр сигнала после CIC фильтра 

    Yout_cic1 = [Yout[i] for i in range(0, len(Yout), D)]   # decimation 
    Xm3 = fft.fft(Yout_cic1, Nf)  # спектр прореженного сигнала
    xf2 = fft.fftfreq(Nf, Ts*8)
    xf2 = fft.fftshift(xf2)

    ###################################################################################
    #### структура фильтра с прореживанием после интегратора и далее гребенчатый фильтр
    Y_int_dec = [Y_int[i] for i in range(0, len(Y_int), D)]   # decimation
    ##### comb filter
    Yp3 = np.pad(Y_int_dec, (0, 2), 'constant',  constant_values=(0, 0)) 
    Yp4 = np.pad(Y_int_dec, (2, 0), 'constant',  constant_values=(0, 0)) # задержанная на N = D/R входная последовательность
    Yout_cic2 = Yp3 - Yp4    

    Xm4 = fft.fft(Yout_cic2, Nf)  # спектр сигнала после прореживающего CIC

    ###################################################################################
    ################### PLOT ##########################################################

    fig = plt.figure(figsize=[10,7])
    gs = GridSpec(nrows=5, ncols=1, figure=fig)
    ax1 = plt.subplot(gs[0,0])
    #ax1.plot(np.abs(Hss))
    #ax1.plot(bb.real, bb.imag)
    ax1.plot(xf, abs(Hcic))
    #ax1.xaxis.set_major_locator(MultipleLocator(base=8))

    ax2 = plt.subplot(gs[1,0])
    #ax2.xaxis.set_major_locator(MultipleLocator(base=2))
    #ax2.plot(Hss_lg[3000:8000])
    #ax2.plot(xf[10:-10], Hcic_lg[10:-10]) # АЧХ cic фильтра дБ
    ax2.plot(Yout_cic2)

    ax3 = plt.subplot(gs[2,0])
    # ax3.yaxis.set_major_locator(MultipleLocator(base=0.1))
    # ax3.xaxis.set_major_locator(MultipleLocator(base=8))
    ax3.plot(xf[Nf//2:], np.abs(Xm[:Nf//2]))
    ax3.plot(xf[Nf//2:], np.abs(Xm2[:Nf//2]))
    #ax3.plot(xf, np.abs(Xm))
    #ax3.plot(Ycomb, '-r')
    
    ax4 = plt.subplot(gs[3,0])
    # ax4.plot(abs(Hm)/abs(Hm).max())
    # ax4.yaxis.set_major_locator(MultipleLocator(base=0.2))
    #ax4.stem(new_sig)
    ax4.plot(Yout)
    #ax4.plot(Yout.real/32)

    ax5 = plt.subplot(gs[4,0])
    #ax5.plot(Yout_cic1)
    #ax5.plot(Yout_cic2)
    ax5.plot(xf2[Nf//2:], np.abs(Xm3[:Nf//2]))
    ax5.plot(xf2[Nf//2:], np.abs(Xm4[:Nf//2]))


    ax1.grid()
    ax2.grid()
    ax3.grid()
    ax4.grid()
    ax5.grid()
    plt.show()




if __name__ == "__main__":
    print("Test fourier")
    test()
