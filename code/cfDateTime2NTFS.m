function a = cfDateTime2NTFS(b)
    a=lower(cfInt2Hex(int64(cfDateToNTFS(datevec(b)))));
end

