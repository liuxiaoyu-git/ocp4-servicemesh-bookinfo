set -e

if [[ -z ${APP_PROJECT} ]]; then
  APP_PROJECT='helloworld'
fi

ISTIO_RELEASE=$(curl --silent https://api.github.com/repos/istio/istio/releases/latest |grep -Po '"tag_name": "\K.*?(?=")')

grep APP_PROJECT $HOME/.bashrc || echo "export APP_PROJECT=$APP_PROJECT" >> $HOME/.bashrc
grep ISTIO_RELEASE $HOME/.bashrc || echo "export ISTIO_RELEASE=$ISTIO_RELEASE" >> $HOME/.bashrc

oc new-project $APP_PROJECT >/dev/null

oc get smmr default -n istio-system -o json --export | jq '.spec.members += ["'"$APP_PROJECT"'"]' | oc apply -n istio-system -f -

oc apply -n $APP_PROJECT -f https://raw.githubusercontent.com/istio/istio/${ISTIO_RELEASE}/samples/helloworld/helloworld.yaml

for deployment in $(oc get deployments -o jsonpath='{.items[*].metadata.name}' -n $APP_PROJECT);do
oc -n $APP_PROJECT patch deployment $deployment -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}'
done

oc apply -n $APP_PROJECT -f https://raw.githubusercontent.com/istio/istio/${ISTIO_RELEASE}/samples/helloworld/helloworld-gateway.yaml

export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')
grep -q GATEWAY_URL $HOME/.bashrc || echo "export GATEWAY_URL=$GATEWAY_URL" >> ~/.bashrc

source $HOME/.bashrc
watch oc get pod
