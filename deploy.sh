docker build -t "wilt:dockerfile" .
docker run -v `pwd`/deploy/:/WiltCollectorBuild/deploy/ wilt:dockerfile
# TODO: automate S3 upload
# TODO: automate Lambda update
