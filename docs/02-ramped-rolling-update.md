# Ramped / Rolling Update

## Objetivo da estratégia

Demonstrar uma atualização gradual de Pods, reduzindo o impacto da troca de versão e preservando disponibilidade durante o rollout.

## Explicação simples

Na estratégia `Rolling Update`, o Kubernetes substitui os Pods aos poucos. Parte da versão antiga continua atendendo enquanto a nova versão entra em operação. Isso torna a atualização mais suave do que `Recreate`.

## Como funciona no Kubernetes

Neste laboratório, a estratégia usa:

- Deployment: `ramped-demo`
- Namespace: `update-strategies`
- Réplicas: `4`
- Estratégia: `RollingUpdate`
- `maxSurge: 1`
- `maxUnavailable: 1`
- Imagem inicial: `update-demo-blue:v1`
- Imagem de atualização: `update-demo-green:v2`
- Service: `ramped-service`

Com essa configuração, o Kubernetes pode criar até um Pod extra durante a atualização e deixar até um Pod indisponível no processo. O resultado é uma substituição controlada e progressiva da versão `blue` pela versão `green`.

## Comandos para executar

Pré-requisitos do laboratório:

```bash
./scripts/setup.sh
./scripts/build-images.sh
./scripts/import-images-k3d.sh
```

Aplicar a versão inicial:

```bash
./scripts/apply-ramped.sh
```

Atualizar para a versão `green`:

```bash
kubectl apply -f manifests/02-ramped/deployment-green.yaml
kubectl rollout status deployment/ramped-demo -n update-strategies
```

## Comandos para verificar

```bash
kubectl get deployment ramped-demo -n update-strategies
kubectl get pods -n update-strategies -l app=ramped-demo -o wide
kubectl rollout history deployment/ramped-demo -n update-strategies
kubectl describe deployment ramped-demo -n update-strategies
kubectl get svc ramped-service -n update-strategies
kubectl get endpoints ramped-service -n update-strategies
```

Para acompanhar a troca em tempo real:

```bash
kubectl get pods -n update-strategies -l app=ramped-demo -w
```

## O que observar durante a execução

- Os Pods da versão antiga e da nova coexistem temporariamente.
- O número de réplicas varia conforme os limites de `maxSurge` e `maxUnavailable`.
- O Service continua apontando para Pods prontos durante o rollout.
- A atualização tende a acontecer sem interrupção total da aplicação.

## Vantagens

- Reduz indisponibilidade.
- É a estratégia padrão e mais comum para aplicações stateless.
- Permite rollout controlado sem duplicar o ambiente inteiro.
- Funciona bem com readiness e liveness probes.

## Limitações

- Exige compatibilidade entre versões que coexistem temporariamente.
- Pode ser mais difícil de analisar do que `Recreate` para quem está começando.
- Nem toda aplicação suporta bem múltiplas versões ao mesmo tempo.

## Cenário recomendado de uso

Essa estratégia costuma ser adequada quando:

- a aplicação precisa manter disponibilidade durante atualizações
- as versões antiga e nova podem coexistir por alguns instantes
- o objetivo é um rollout progressivo sem manter dois ambientes completos
- o sistema é stateless e tolera substituição gradual dos Pods

## Evidências, prints ou logs

Registre evidências que mostrem a progressão do rollout:

- saída de `kubectl get pods -n update-strategies -l app=ramped-demo -w`
- saída de `kubectl rollout history deployment/ramped-demo -n update-strategies`
- print do `describe` do Deployment com os parâmetros de Rolling Update
- print de `kubectl get endpoints ramped-service -n update-strategies`
- observações sobre a convivência temporária entre versões
