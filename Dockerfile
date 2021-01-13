FROM registry.svc.ci.openshift.org/ocp/builder:rhel-8-golang-1.15-openshift-4.7 AS builder
WORKDIR /go/src/github.com/openshift/network-tools
COPY . .

# tools (openshift-tools) is based off cli
FROM registry.svc.ci.openshift.org/ocp/4.7:tools
COPY --from=builder /go/src/github.com/openshift/network-tools/debug-scripts/* /usr/bin/

RUN INSTALL_PKGS="\
    git \
    go \
    make \
    nginx \
    numactl \
    traceroute \
    wireshark \
    " && \
    yum -y install --setopt=tsflags=nodocs --setopt=skip_missing_names_on_install=False $INSTALL_PKGS && \
    yum clean all && rm -rf /var/cache/* && \
    # needed for ovnkube-trace
    git clone https://github.com/openshift/ovn-kubernetes.git /usr/bin/ovn-kubernetes && \
    pushd /usr/bin/ovn-kubernetes/go-controller && hack/build-go.sh cmd/ovnkube-trace && \
    mv _output/go/bin/ovnkube-trace /usr/bin/ovnkube-trace && popd && \
    rm -rf /usr/bin/ovn-kubernetes