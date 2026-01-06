function newObj = copyHandle(obj)
    byteStream = getByteStreamFromArray(obj);
    newObj = getArrayFromByteStream(byteStream);
end