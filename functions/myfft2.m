function result = myfft2(input)
%centered input output
result = fftshift(fft2(ifftshift(input)));