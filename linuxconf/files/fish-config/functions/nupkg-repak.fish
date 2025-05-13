function nupkg-repak
set nu $argv[1]
mkdir -p $nu.wd ; cd $nu.wd
unzip ../$nu ; or unzip $nu ; or return 1
cd content/Redist
rm remote/*.lib ; rm remote/*.pdb ; rm -f remote/no-grpc/vfpremoteapi.lib ; cd ..
zip -r r.zip Redist ; or return 2
echo "DONE. CHECK r.zip"
end
