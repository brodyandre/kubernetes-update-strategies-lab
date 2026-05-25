# Canary

## Objetivo da estratégia

Demonstrar uma liberação gradual da nova versão da aplicação, expondo apenas uma parte do tráfego antes da promoção completa.

## Explicação simples

Na estratégia `Canary`, a maior parte dos usuários continua acessando a versão estável, enquanto uma parcela menor passa a receber a nova versão. Isso reduz o risco da mudança e permite validação progressiva.

## Como funciona no Kubernetes

Neste laboratório, a estratégia usa:

- Deployment estável: `canary-stable-blue`
- Deployment canário: `canary-green`
- Namespace: `update-strategies`
- Service: `canary-service`
- Manifest de promoção: `manifests/04-canary/promote-green.yaml`

O Service seleciona Pods com `app: canary-demo`. Como existem `4` réplicas `blue` e `1` réplica `green`, a distribuição do tráfego é simulada pela quantidade de Pods disponíveis, aproximando um cenário de `80%` para a versão estável e `20%` para a nova versão.

## Comandos para executar

Pré-requisitos do laboratório:

```bash
./scripts/setup.sh
./scripts/build-images.sh
./scripts/import-images-k3d.sh
```

Aplicar a estratégia:

```bash
./scripts/apply-canary.sh
```

Promover a versão `green`:

```bash
kubectl apply -f manifests/04-canary/promote-green.yaml
kubectl scale deployment canary-stable-blue -n update-strategies --replicas=0
kubectl scale deployment canary-green -n update-strategies --replicas=0
kubectl rollout status deployment/canary-stable-green -n update-strategies
```

## Comandos para verificar

```bash
kubectl get deployments -n update-strategies
kubectl get pods -n update-strategies -l app=canary-demo -o wide
kubectl get pods -n update-strategies -l app=canary-demo --show-labels
kubectl get svc canary-service -n update-strategies
kubectl get endpoints canary-service -n update-strategies
kubectl describe deployment canary-stable-blue -n update-strategies
kubectl describe deployment canary-green -n update-strategies
```

Para testar a aplicação internamente:

```bash
kubectl run curl-test -n update-strategies --rm -it \
  --image=curlimages/curl --restart=Never -- \
  curl http://canary-service
```

## O que observar durante a execução

- A versão `blue` continua predominante durante a fase inicial.
- A versão `green` já recebe parte do tráfego mesmo antes da promoção completa.
- A distribuição é aproximada e baseada na quantidade de Pods selecionados pelo Service.
- A promoção da nova versão exige uma ação explícita, o que ajuda no controle operacional.

## Vantagens

- Reduz risco ao limitar a exposição inicial da nova versão.
- Permite observação gradual antes da promoção completa.
- Ajuda a validar comportamento da aplicação com menor impacto.
- É uma abordagem útil para mudanças com mais incerteza.

## Limitações

- A distribuição por quantidade de Pods é apenas uma aproximação do tráfego.
- Exige acompanhamento mais cuidadoso do que estratégias mais simples.
- Pode se tornar mais complexa quando aplicada a cenários de produção reais.

## Cenário recomendado de uso

Essa estratégia costuma ser adequada quando:

- a nova versão precisa ser exposta gradualmente
- existe preocupação com risco funcional ou operacional
- o time quer observar comportamento antes da promoção total
- a aplicação se beneficia de uma transição mais cautelosa

## Evidências, prints ou logs

Registre evidências que mostrem a distribuição parcial e a promoção:

- print de `kubectl get pods -n update-strategies -l app=canary-demo --show-labels`
- print de `kubectl get endpoints canary-service -n update-strategies`
- saída de `kubectl describe deployment canary-stable-blue -n update-strategies`
- saída de `kubectl describe deployment canary-green -n update-strategies`
- prints antes e depois da promoção com `promote-green.yaml`
