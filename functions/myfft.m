function result = myfft(input)
%centered input output
result = fftshift(fft(ifftshift(input)));
end