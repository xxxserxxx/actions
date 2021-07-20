entr=`date -r entrypoint.sh`
dock=`date -r Dockerfile`
imag=`podman inspect builder | jq -r '.[0].Created'`

imag_ts=`date -d "$imag" +%s`
dock_ts=`date -d "$dock" +%s`
entr_ts=`date -d "$entr" +%s`

echo image       : $image_ts
echo Dockerfile  : $dock_ts
echo entrypoint  : $entr_ts

if [[ $imag_ts -lt $entr_ts || $imag_ts -lt $dock_ts ]]
then
	podman rmi builder
fi
