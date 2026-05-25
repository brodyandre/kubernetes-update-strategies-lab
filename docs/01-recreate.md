# Recreate

## Objetivo da estratégia

Demonstrar uma atualização em que a versão antiga da aplicação é encerrada antes do início da nova versão. Essa abordagem é útil para entender uma troca simples de versão e seus impactos diretos em disponibilidade.

## Explicação simples

Na estratégia `Recreate`, o Kubernetes remove os Pods da versão atual e, somente depois disso, cria os Pods da nova versão. Em termos práticos, a aplicação sai do ar por um curto período e volta já com a nova imagem.

## Como funciona no Kubernetes

Neste laboratório, a estratégia usa:

- Deployment: `recreate-demo`
- Namespace: `update-strategies`
- Réplicas: `3`
- Estratégia: `Recreate`
- Imagem inicial: `update-demo-blue:v1`
- Imagem de atualização: `update-demo-green:v2`
- Service: `recreate-service`

O Deployment é criado primeiro com a versão `blue`. Quando o manifesto da versão `green` é aplicado, o Kubernetes encerra os Pods antigos e sobe novos Pods com a imagem atualizada.

## Comandos para executar

Pré-requisitos do laboratório:

```bash
./scripts/setup.sh
./scripts/build-images.sh
./scripts/import-images-k3d.sh
```

Aplicar a estratégia com a versão inicial:

```bash
./scripts/apply-recreate.sh
```

Atualizar para a versão `green`:

```bash
kubectl apply -f manifests/01-recreate/deployment-green.yaml
kubectl rollout status deployment/recreate-demo -n update-strategies
```

## Comandos para verificar

```bash
kubectl get deployment recreate-demo -n update-strategies
kubectl get pods -n update-strategies -l app=recreate-demo -o wide
kubectl describe deployment recreate-demo -n update-strategies
kubectl get svc recreate-service -n update-strategies
kubectl get endpoints recreate-service -n update-strategies
```

Para uma visão geral do namespace:

```bash
./scripts/check.sh
```

## O que observar durante a execução

- Os Pods da versão antiga são encerrados antes do início da nova versão.
- Pode haver um intervalo sem endpoints disponíveis no Service.
- O rollout tende a ser simples de entender e fácil de acompanhar.
- A troca da imagem fica explícita no Deployment `recreate-demo`.

## Vantagens

- Implementação simples.
- Comportamento previsível.
- Útil para estudo inicial de atualização de aplicações.
- Pode ser suficiente para cargas não críticas ou ambientes internos.

## Limitações

- Pode causar indisponibilidade durante a troca.
- Não é a melhor opção para aplicações que exigem alta disponibilidade.
- Não permite convivência entre versões antiga e nova.

## Cenário recomendado de uso

Essa estratégia costuma ser adequada quando:

- a aplicação pode tolerar uma breve indisponibilidade
- existe janela de manutenção definida
- a simplicidade operacional é mais importante que continuidade total do serviço
- a nova versão não deve coexistir com a antiga

## Evidências, prints ou logs

Registre evidências que mostrem com clareza o comportamento da troca:

- saída de `kubectl get pods -n update-strategies -l app=recreate-demo -o wide`
- saída de `kubectl describe deployment recreate-demo -n update-strategies`
- print do momento antes e depois da atualização para `green`
- print de `kubectl get endpoints recreate-service -n update-strategies`
- logs ou observações sobre eventual indisponibilidade temporária
