# private-aca-with-fw-proxy-dns
##  Architecture 
* Hub spoke networking. Peering to onprem and spokes 
* Spoke traffic Forced tunneling with through FW in HUB
  * currently all traffic is generally allowed out
* FW acts as DNS Proxy (So FW can do L7 rules)
* DNS private resolver in Hub
* DNS forwarding rule in hub to forward all *.example.com dns queries to a example coredns deployment. 
  * Simple Core DNS, Container instance,  is acting as upstream dns server. 
  * simulates a typical onprem connected setup for DNS.
  * the core dns is deployed in a delegate subnet in the hub


![ddfdd](/assets%20/hubspoke.png)

## To deploy 
modify the variables in the file bicep/deploy.sh 
```
SUFFIX="35"
DEPLOYMENTNAME="acade2"-$SUFFIX
```
These simply ensure the deplyoments are unique. 
### Execute 
```
./deploy.sh 
```
