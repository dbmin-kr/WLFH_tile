function result = myifft(input)
%centered input output
result = fftshift(ifft(ifftshift(input)));