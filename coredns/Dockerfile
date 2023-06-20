## https://devpress.csdn.net/cloudnative/62f219edc6770329307f5f7d.html
## https://coredns.io/2017/07/24/quick-start/
## https://www.codevieillard.tech/blog/run-coredns-locally/
## How to test
## dig @10.10.2.4 test.example.com +nocmd +noall +answer +ttlid 
FROM coredns/coredns

COPY Corefile /root/Corefile
COPY example.com /root/example.com
EXPOSE 53
ENTRYPOINT ["/coredns", "-conf", "/root/Corefile"]