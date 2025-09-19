function aria2rpc --wraps='aria2c --enable-rpc --rpc-listen-all --rpc-allow-origin-all' --description 'alias aria2rpc=aria2c --enable-rpc --rpc-listen-all --rpc-allow-origin-all'
  aria2c --enable-rpc --rpc-listen-all --rpc-allow-origin-all $argv
        
end
