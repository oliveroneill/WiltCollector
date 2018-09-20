docker build -t "wilt:dockerfile" .
docker run -v `pwd`/deploy/:/WiltCollectorBuild/deploy/ wilt:dockerfile