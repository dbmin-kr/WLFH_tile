function result = myifft2(input)
%centered input output
result = fftshift(ifft2(ifftshift(input)));