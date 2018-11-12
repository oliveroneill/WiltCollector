docker build -t "wilt:dockerfile" .
docker run -v `pwd`/:/WiltCollectorBuild/ wilt:dockerfile
# TODO: automate S3 upload
# TODO: automate Lambda update
